require 'rubygems'
require 'mechanize'
require 'debugger'

def yahoo_data(ticker)
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }
  #ticker = "AAPL"
  url = "http://finance.yahoo.com/q/pr?s=" + ticker + "+Profile"
  a.get(url)
  #do |page|
  #  search_result = page.form_with(:name => 'quote'){ |frm|
  #    frm.s = 'F'
  #  }.submit
  #a.page.link_with(:text => 'Profile').click
  text = a.page.search('td.yfnc_modtitlew1')
  #debugger
  address = ""
  first_add = nil
  phone_num = ""
  fax_num = ""
  website = ""
  text.children.each do |child|
    if child.instance_of?(Nokogiri::XML::Text)
      st = child.to_s
      if st.index("Phone:")
        phone_num = st.split("Phone: ").last 
      elsif st.index("Fax:")
        fax_num = st.split("Fax: ").last
      elsif st.index("Website")
        website = child.next.text.strip
      else
        if(first_add)
          first_add = 1
          address.concat(", ")
        end
        address.concat(st)
      end
    end
  end

  puts "address: " + address
  puts "phone: " + phone_num
  puts "fax: " + fax_num
  puts "website: " + website

  titles = a.page.search("//td[@class='yfnc_modtitlew1']//td[@class='yfnc_tablehead1']")
  content = a.page.search("//td[@class='yfnc_modtitlew1']//td[@class='yfnc_tabledata1']")
  index_mem = ""
  sector = ""
  industry = ""
  employee_num = ""
  titles.zip(content).each do |title, stuff|
    st = stuff.text.strip
    ind = title.to_s
    if ind.index("Index Membership:")
      index_mem=st
    elsif ind.index("Sector:")
      sector = st
    elsif ind.index("Industry:")
      industry = st
    elsif ind.index("Full Time Employees:")
      employee_num = st
    end
  end

  puts "mem: " + index_mem
  puts "sector: " + sector
  puts "industry: " + industry
  puts "employee_#: " + employee_num

  url = "http://finance.yahoo.com/q/is?s=" + ticker + "+Income+Statement&annual"
  a.get(url)

  total_size = index_mem.size + sector.size + industry.size + employee_num.size + address.size + phone_num.size + fax_num.size + website.size
  if(total_size < 12)
    f = File.open("failures.txt", "a+")
    f.syswrite(ticker + "\n")
    f.close
    [0, 1]
  else
    [1, 1]
  end
  end

  def call_letters(letter)
    a = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
    success = [0, 0]
    url = "http://en.wikipedia.org/wiki/Companies_listed_on_the_New_York_Stock_Exchange_(" + letter + ")"
    a.get(url)
    ret = [0,0]
    rows = a.page.search("//table[@style='background:transparent;']//tr")
    puts rows[2].children[3]
    rows.each do |row|
      stock_sym = row.children[3].text.strip
      if (stock_sym.index("Symbol"))
        stock_sym = "invalid"
      else
        puts stock_sym
        ret = yahoo_data(stock_sym)
        success[0] += ret[0]
        success[1] += ret[1]
        puts("")
      end
    end
    success
  end
  f = File.new("failures.txt", "w+")
  f.syswrite("these failed: \n")
  f.close()
  find_rate = [0,0]
  letter_rate = call_letters("0-9")
  #"A".upto("B") {|i|
  #  new_rate = call_letters(i)
  #  letter_rate[0] += new_rate[0]
  #  letter_rate[1] += new_rate[1]
 # }
  puts letter_rate
