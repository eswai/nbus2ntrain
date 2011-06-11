# coding: utf-8

require 'hpricot'
require 'open-uri'

class Nbus2ntrain
  
  HEAD = ['[MON][TUE][WED][THU][FRI]', '[SAT]', '[SUN][HOL]']
  MARK = "abcdefghijk"
  
  def convert(uri)
    hsh = parse(uri)
    nexttrain(hsh)
  end
  
  def parse(uri)
    res = {}
    doc = Hpricot.parse(open(uri, "r:sjis").read.encode("utf-8", :invalid => :replace, :undef => :replace))
    res['name'] = doc.search("th[text()='停留所名']")[0].next.at('b').inner_text.strip
    res['category'] = doc.search("th[text()='系統']")[0].next.at('a').inner_text.strip
    res['destination'] = destination(doc)
    res['table'] = ttable(doc)
    res
  end
  
  def destination(doc)
    dst1 = doc.search("th[text()='行き先']")[0].next.inner_text.strip
    dst2 = dst1.split("\n")
    dst3 = {}
    
    @dmark = {} # ◯とaの対応テーブル
    i = 0
    dst2.each do |s|
      dst4 = s.split("・・・")
      next if dst4.size < 2
      @dmark[dst4[0]] = MARK[i]
      dst3[MARK[i]] = dst4[1].gsub(/\(ノンステ.*\)/,'')
      i += 1
    end
    dst3
  end
  
  def ttable(doc)
    rtab = {}
    HEAD.each do |h|
      rtab[h] = {}
    end
    
    tab = doc.search("table")[5].search("tr")
    tab.each do |t| # 時間ごとに
      hh = t.search("th")
      next if hh.inner_text =~ /^[^0-9]/ # ヘッダは飛ばす
      mm1 = t.search("table")
      for j in 0 .. hh.size - 1 # 平日、土曜、日曜ごとに
        key = hh[j].inner_text
        mm2 = mm1[j].search("td")
        next if mm2.inner_text.size < 1 # 空欄の時刻は飛ばす
        rtab[HEAD[j]].store(key, minutes(mm2))
      end
    end
    rtab
  end
  
  def minutes(doc)
    mm3 = []
    doc.each do |m| # 分ごとに
      mm4 = m.inner_text
      mm_num = mm4.scan(/([0-9]+)/).flatten[0]
      mm_mrk = mm4.scan(/([^0-9]+)/).flatten[0]
      mm_mrk ||= '無印'
      mm3 << @dmark[mm_mrk] + mm_num
    end
    mm3
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
    
    HEAD.each do |h|
      res += "#{h}\n"
      hsh['table'][h].each do |k, v|
        res += "#{k}:#{v.join(' ')}\n"
      end
    end
    
    res
  end
end

nt = Nbus2ntrain.new
print nt.convert(ARGV.shift)

