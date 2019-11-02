#! ruby -Ku
# -*- mode:ruby; coding:utf-8 -*
# 英辞郎の英和辞書をMac OS X v10.5 "Leopard"の辞書アプリケーション（Dictionary.app）用に変換
# v0.09 by Tats_y (http://www.binword.com/blog/)
# 2011/04/10

require 'iconv'
require 'cgi'

word_index = Hash.new
word_id = Hash.new
word_definition = Hash.new
wordclass = ""
word_conj = Hash.new{|word_conj, key| word_conj[key] = [] }  # 変化形のために、複数の値に対応するハッシュを作成
temp1_conj = Array.new
temp2_conj = Array.new
temp3_conj = Array.new
temp_array = Array.new

# URLチェック用の正規表現を生成
  digit         = "[0-9]"
  hex           = "[0-9a-fA-F]"
  alpha         = "[A-Za-z]"
  alphanum      = "[A-Za-z0-9]"
  reserved      = "[;/?:@&=+$,]"
  unreserved    = "[A-Za-z0-9\\-_.!~*'()]"
  escaped       = "%#{hex}#{hex}"
  pchar         = "(?:[A-Za-z0-9\\-_.!~*'():@&=+$,]|#{escaped})"
  param         = "#{pchar}*"
  segment       = "#{pchar}*(?:;#{param})*"
  path_segments = "#{segment}(?:/#{segment})*"
  abs_path      = "/#{path_segments}"
  port          = "#{digit}*"
  ipv4address   = "#{digit}+\\.#{digit}+\\.#{digit}+\\.#{digit}+"
  uric          = "(?:[;/?:@&=+$,A-Za-z0-9\\-_.!~*'()]|#{escaped})"
  query         = "#{uric}*"
  domainlabel   = "#{alphanum}(?:[A-Za-z0-9\\-]*#{alphanum})?"
  toplabel      = "#{alpha}(?:[A-Za-z0-9\\-]*#{alphanum})?"
  hostname      = "(?:#{domainlabel}\\.)*#{toplabel}\\.?"
  host          = "(?:#{hostname}|#{ipv4address})"
  http_URL      = 
      "http://#{host}(?::#{port})?(?:#{abs_path}(?:\\?#{query})?)?"
  http    = "【URL】(#{http_URL})"
  $re_http = Regexp.new(http)	# URLチェック用の正規表現はグローバル変数


while line = gets
  next if line.strip.empty?
  temp_word = /^■/.match(/\s:\s/.match(line).pre_match).post_match  #見出しと定義に分割
  if /\{.*\}/.match(temp_word).nil? then  #品詞が含まれているものはさらに分割
    temp_index = temp_word.strip
  elsif
    temp_index = /\{.*\}/.match(temp_word).pre_match.to_s.strip
    wordclass = /\{.*\}/.match(temp_word).to_s
  end
  next if temp_index.length > 512 #見出し語が長すぎる項目はスキップ
  definition =  /\s:\s/.match(line).post_match.chomp
  id = temp_index.unpack("C*").map!{|i| i.to_s(16)}.join("")  #一意のIDを付与（文字コードで表現）
  word_index[id] = CGI::escapeHTML(temp_index)
  temp1_conj = definition.scan(/【変化】([^【■]+)/)  # 【変化】が2つ以上ある場合、配列に分解
  temp1_conj.each{|elem|
    temp2_conj.concat(elem.to_s.gsub(/《.+?》/,"").split(/[^a-zA-Z\(\)]+/))  # 「;-、空白」などで区切られた要素を分解
    temp2_conj.map!{|x|  # 分解された変化形のうち、()を含むものを抽出して括弧がある場合とない場合に展開（evil(l)erなど）
      if /\(.+?\)/ =~ x then
        x = [ x.gsub(/[\(\)]/, ""), x.gsub(/\(.+?\)/, "") ]  # ()を含む変化形を、展開した変化形の配列で置き換える
      else
        x = x
      end

    }
  }
  temp2_conj.flatten!  # 変化形によっては、配列内に配列があるので（evilなど）、フラット化
  word_conj[id].concat(temp2_conj)
  word_conj[id].uniq!  # 同じ変化形は1つにまとめる
  word_conj[id].delete("") # 空の要素を削除
  temp2_conj.clear

  if word_definition[id].nil? then
    word_definition[id] = wordclass + definition + "Ⓐ"  #あとから改行を置換しやすいよう行末にⒶ
    wordclass = ""
  elsif
    word_definition[id] = word_definition[id] + wordclass + definition + "Ⓐ"
    wordclass = ""
  end
end


print '<?xml version="1.0" encoding="UTF-8"?>' + "\n"
print '<d:dictionary xmlns="http://www.w3.org/1999/xhtml" xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng">' + "\n"

word_index.each{|x, value|
  print "<d:entry id=\"" + x + "\" d:title=\"" + value +"\">\n"
  print "\t<d:index d:value=\"" + value + "\" />\n"
  word_conj[x].delete(value)
  word_conj[x].each{|elem|
    print "\t<d:index d:value=\"" + elem + "\" " "d:title=\"" + elem +" (" +value + ")\" />\n"  # ハッシュに格納してある変化形でも引けるようにする
  }
  print "\t<h1>" + value + "</h1>\n"

word_definition[x] = CGI::escapeHTML(word_definition[x])  # HTMLのタグをエスケープ
word_definition[x] = word_definition[x].gsub(/&lt;→(.+?)&gt;/){  # リンク先が複数ある場合（「;」で区切られている）、各要素を展開
  temp_array = $1.split(/\s;\s/)
  temp_array.map!{|elem|  # ()や[]などを含むリンクについては、表記はそのまま、実際のリンクは()や[]を除いた項目へ
    elem = %Q[<a href="x-dictionary:r:#{elem.gsub(/\[.+?\]|\(.+?\)|\{.+?\}/,"").strip.gsub(/\s+/, " ").unpack("C*").map!{|i| i.to_s(16)}.join("")}">#{elem.strip}</a>]
  }
  "&lt;→" + temp_array.join(" ; ") + "&gt;"
}

  word_definition[x] = word_definition[x].gsub($re_http){%Q[【URL】<a href="#$1">#$1</a>]}  # リンクの処理
  word_definition[x] = word_definition[x].gsub(/\{([0-9]+)\}/) {%Q[#{"<span class=\"order\">" + $1 +"</span>"}]}  #「数値のみ」のスタイル指定
  word_definition[x] = word_definition[x].gsub(/\{([^Ⓐ]{1,10})-1\}/) {%Q[#{"<span class=\"wordclass\">" + $1 +"</span><br /><span class=\"order\">1</span>"}]}  #「品詞名-1」のスタイル指定
  word_definition[x] = word_definition[x].gsub(/\{([^Ⓐ]{1,10})-([0-9]{1,3})\}/) {%Q[#{"<span class=\"order\">" + $2 +"</span>"}]}  #「品詞名-2以降」のスタイル指定
  word_definition[x] = word_definition[x].gsub(/\{([^Ⓐ]{1,10})\}/) {%Q[#{"<span class=\"wordclass\">" + $1 +"</span><br />"}]}  #「品詞名のみ」のスタイル指定

word_definition[x] = word_definition[x].gsub(/■(.+?)Ⓐ/) {"<div class=\"example\">" + $1.gsub(/■/, "<br />") + "</div>Ⓐ"}  # 文例のスタイル指定

#  word_definition[x] = word_definition[x].gsub(/■(.+?)Ⓐ/) { "Ⓐ<span class=\"example\">" + $1.gsub(/■/, "</span><br /><span class=\"example\">") + "</span>Ⓐ"}  #文例のスタイルをspanで指定する場合

  word_definition[x] = word_definition[x].gsub(/｛(.+?)｝/) {"<span class=\"ruby\">（"+$1+"）</span>"}

  word_definition[x] = word_definition[x].gsub(/<\/div>Ⓐ/, "</div>")  #<div class="example"> ... </div> の後では改行しないようにする
  word_definition[x] = word_definition[x].gsub(/Ⓐ【/, "<br /><br />【")  #語義説明の最後にある【レベル】などの前にはあえて空行を入れる

  print "\t<p>" + word_definition[x].gsub(/Ⓐ$/, "").gsub(/Ⓐ/, "<br />") + "</p>\n"
  print "</d:entry>\n"
}
print "</d:dictionary>"

