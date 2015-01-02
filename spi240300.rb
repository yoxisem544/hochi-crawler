require 'rest_client'
require 'nokogiri'
require 'json'
require 'iconv'
require 'uri'
require_relative 'course.rb'
# 難得寫註解，總該碎碎念。
class Spider
  attr_reader :semester_list, :courses_list, :query_url, :result_url

  def initialize
  	@query_url = "http://hochitw.com/index_down.php"
  	@result_url = "https://sea.cc.ntpu.edu.tw/pls/dev_stud/course_query_all.queryByKeyword"
    @front_url = "http://hochitw.com/index_down.php"
  end

  def prepare_post_data
    r = RestClient.get @query_url
    query_page = Nokogiri::HTML(r.to_s)

    puts "post data preparing......."
    # 撈第一次資料，拿到 hidden 的表單驗證。 
    @searchfirestime = 1
    @sele = 'searchRS'
    @advsearch_ai = 'ai'
    @searchPCON1 = 'ItemName'
    @searchname1_bigsmall = 'LIKE'
    @Submit = '開始檢索'
    @Page = 4

    nil
  end

  def get_courses(sem = 0)
  	# 初始 courses 陣列
    @books = []
    puts "getting courses\n"
    # 把表單驗證，還有要送出的資料弄成一包 hash
    post_data = {
      # 看是第幾學年度，預設用最新的
      :searchfirestime => @searchfirestime,
      :sele => @sele,
      :advsearch_ai => @advsearch_ai,
      :searchPCON1 => @searchPCON1,
      :searchname1_bigsmall => @searchname1_bigsmall,
      :Submit => @Submit,
      :Page => @Page
    }

    @progress = 0
    @all_task = 20*14.0
    puts @all_task

    (241..300).each do |page|
      
      puts "page #{page}"
      post_data[:Page] = page
      r = RestClient.post(query_url, post_data)
      ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
      @list = Nokogiri::HTML(ic.iconv(r.to_s))

      # test
      # puts @list.css('table')[241].css('a')[2]['href'].to_s

      @tmp_rul = ""
      @now_url = ""
      i = 241
      14.times {
        @now_url = @list.css('table')[i].css('a')[2]['href'].to_s
        while @now_url == @tmp_rul do
          i += 1
          @tmp_rul = @list.css('table')[i].css('a')[2]['href'].to_s
        end

        if @tmp_rul == ""
          puts "hi"
        else
          @now_url = @list.css('table')[i].css('a')[2]['href'].to_s
        end

        puts @now_url
        # jump to next
        puts "i is #{i}"
        i += 1


        # appending string to a usable url & get data
        rr = RestClient.get(@front_url + @now_url)
        # get detail things
        ic = Iconv.new("utf-8//translit//IGNORE","utf-8")
        @detail = Nokogiri::HTML(ic.iconv(rr.to_s))
        # puts 詳細資料
        book_category = @detail.css('table')[254].css('a')[0].text
        detailed_book_category = @detail.css('table')[254].css('a')[1].text
        book_name = @detail.css('table')[254].css('font').text
        book_number = @detail.css('table')[254].css('div')[3].text
        if @detail.css('table')[254].css('div')[5].nil?
          price = "no price"
        else
          price = @detail.css('table')[254].css('div')[5].text
        end
        if @detail.css('table')[254].css('div')[7].nil?
          selling_price = "no price"
        else
          selling_price = @detail.css('table')[254].css('div')[7].text
        end
        if @detail.css('table')[254].css('div')[9].nil?
          isbn = "no ISBN"
        else
          isbn = @detail.css('table')[254].css('div')[9].text
        end
        if @detail.css('table')[254].css('div')[11].nil?
          author_translator = "無"
        else
          author_translator = @detail.css('table')[254].css('div')[11].text
        end
        if @detail.css('table')[254].css('div')[13].nil?
          edition = "no edition / 無版次"
        else
          edition = @detail.css('table')[254].css('div')[13].text
        end

        puts book_name
        @books << Course.new({
            :book_category => book_category,
            :detailed_book_category => detailed_book_category,
            :book_name => book_name,
            :book_number => book_number,
            :price => price,
            :selling_price => selling_price,
            :isbn => isbn,
            :author_translator => author_translator,
            :edition => edition
          }).to_hash
      @tmp_rul = @now_url
      # progress
      @progress += 1
      hello = @progress/@all_task * 100
      puts "now => #{hello} %"
      }
    end
    
    puts "\n\n"
    puts @books
    end
  

    def save_to(filename='courses_p13.json')
	    File.open(filename, 'w') {|f| f.write(JSON.pretty_generate(@books))}
	  end
    
  end






spider = Spider.new
spider.prepare_post_data
spider.get_courses
spider.save_to
