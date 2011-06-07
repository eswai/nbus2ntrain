# coding: utf-8

require 'hpricot'
require 'open-uri'
require 'pp'

HEAD = ['WDAY', 'SAT', 'SUN']
MARK = {'無印' => 'a','〇' => 'b','△' => 'c','×' => 'd','◎' => 'e','■' => 'f'}

def parse(uri)
  res = {}
  doc = Hpricot.parse(open(uri, "r:sjis").read.encode("utf-8", :invalid => :replace, :undef => :replace))
  res['name'] = doc.search("th[text()='停留所名']")[0].next.at('b').inner_text.strip
  res['category'] = doc.search("th[text()='系統']")[0].next.at('a').inner_text.strip
  
  dst1 = doc.search("th[text()='行き先']")[0].next.inner_text.strip
  dst2 = dst1.split("\n")
  dst3 = {}
  dst2.each do |s|
    dst4 = s.split("・・・")
    MARK.each do |k, v|
      dst4[0].gsub!(k, v)
    end
    dst3[dst4[0]] = dst4[1].gsub(/\(ノンステ.*\)/,'')
  end
  res['destination'] = dst3
  
  rtab = {}
  res['table'] = rtab
  for i in 0..2
    rtab[HEAD[i]] = {}
  end
  
  tab = doc.search("table")[5].search("tr")
  for i in 1..tab.size - 1
    hh = tab[i].search("th")
    mm1 = tab[i].search("table")
    for j in 0 .. hh.size - 1
      key = hh[j].inner_text
      mm2 = mm1[j].search("td")
      mm3 = []
      for k in 0 .. mm2.size - 1
        mm4 = mm2[k].inner_text
        MARK.each do |k, v|
          mm4.gsub!(k, v)
        end
        mm4 = "a" + mm4 if mm4 =~ /^[0-9]+$/
        mm3 << mm4
      end
      rtab[HEAD[j]].store(key, mm3)
    end
  end
  res
end

def nexttrain(hsh)
  return unless hsh
  res = ''
  res += ";停留所名: #{hsh['name']}\n"
  res += ";系統: #{hsh['category']}\n"
  res += ";行き先: #{hsh['destination'].values.join('/')}\n"
  
  hsh['destination'].each do |k, v|
    res += "#{k}:#{v}\n"
  end
  
  res += "[MON][TUE][WED][THU][FRI]\n"
  hsh['table']['WDAY'].each do |k, v|
    res += "#{k}:#{v.join(' ')}\n"
  end
  res += "[SAT]\n"
  hsh['table']['SAT'].each do |k, v|
    res += "#{k}:#{v.join(' ')}\n"
  end
  res += "[SUN][HOL]\n"
  hsh['table']['SUN'].each do |k, v|
    res += "#{k}:#{v.join(' ')}\n"
  end
  
  res
end

r = parse(ARGV.shift)
print nexttrain(r)

