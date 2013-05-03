require 'rubygems'
require 'mechanize'
require 'debugger'

class Profile
  attr_accessor :address, :phone_num, :fax_num, :website, :index_mem, :sector, :industry, :employee_num, :revenue, :period_end, :last_revenue, :last_period_end, :company_name
end

def yahoo_data(ticker)
  a = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }
  ret_val = Profile.new()
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
  name = a.page.search('td.yfnc_modtitlew1/b')
  ret_val.company_name = ""
  if(name[0])
    ret_val.company_name = name[0].text.strip
    puts ret_val.company_name 
  end
  ret_val.address = ""
  first_add = 1
  ret_val.phone_num = ""
  ret_val.fax_num = ""
  ret_val.website = ""
  text.children.each do |child|
    if child.instance_of?(Nokogiri::XML::Text)
      st = child.to_s
      if st.index("Phone:")
        ret_val.phone_num = st.split("Phone: ").last 
      elsif st.index("Fax:")
        ret_val.fax_num = st.split("Fax: ").last
      elsif st.index("Website")
        ret_val.website = child.next.text.strip
      else
        if(first_add)
          ret_val.address.concat(st)
          first_add = nil
        else
          ret_val.address.concat(", " + st)
        end
      end
    end
  end

  puts "address: " + ret_val.address
  puts "phone: " + ret_val.phone_num
  puts "fax: " + ret_val.fax_num
  puts "website: " + ret_val.website

  titles = a.page.search("//td[@class='yfnc_modtitlew1']//td[@class='yfnc_tablehead1']")
  content = a.page.search("//td[@class='yfnc_modtitlew1']//td[@class='yfnc_tabledata1']")
  ret_val.index_mem = ""
  ret_val.sector = ""
  ret_val.industry = ""
  ret_val.employee_num = ""
  titles.zip(content).each do |title, stuff|
    st = stuff.text.strip
    ind = title.to_s
    if ind.index("Index Membership:")
      ret_val.index_mem=st
    elsif ind.index("Sector:")
      ret_val.sector = st
    elsif ind.index("Industry:")
      ret_val.industry = st
    elsif ind.index("Full Time Employees:")
      ret_val.employee_num = st
    end
  end

  puts "index_membership: " + ret_val.index_mem
  puts "sector: " + ret_val.sector
  puts "industry: " + ret_val.industry
  puts "employee_#: " + ret_val.employee_num

  url = "http://finance.yahoo.com/q/is?s=" + ticker + "+Income+Statement&annual"
  a.get(url)

  ret_val.period_end = ""
  ret_val.revenue = ""
  ret_val.last_period_end = ""
  ret_val.last_revenue = ""
  date = a.page.search("//tr[@class='yfnc_modtitle1']/th")
  rev = a.page.search("//tr/td[@align='right']/strong")
  if(date.children[0])
    ret_val.period_end = date.children[0].text.strip
    ret_val.revenue = rev.children[0].text.strip
  end
  if(date.children[1])
    ret_val.last_period_end = date.children[1].text.strip
    ret_val.last_revenue = rev.children[1].text.strip
  end

  # period_end = date.children[0].text.strip
  #revenue = rev.children[0].text.strip
  puts "period ending: " + ret_val.period_end
  puts "revenue: " + ret_val.revenue

  puts "last period: " + ret_val.last_period_end
  puts "last reveneue: " + ret_val.last_revenue
  total_size = ret_val.index_mem.size + ret_val.sector.size + ret_val.industry.size + ret_val.employee_num.size + ret_val.address.size + ret_val.phone_num.size + ret_val.fax_num.size + ret_val.website.size
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
"A".upto("B") {|i|
  new_rate = call_letters(i)
  letter_rate[0] += new_rate[0]
  letter_rate[1] += new_rate[1]
}
puts letter_rate
