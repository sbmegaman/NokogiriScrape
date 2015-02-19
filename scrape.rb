# coding: utf-8
require 'open-uri'
require 'nokogiri'
require 'uri'
require './functions.rb'
require './db.rb'

# ---------------------------------
# 初期化
# ---------------------------------
TARGET_WORD       = "hoge" # 住所とセットで検索したいワード
BASE_URL          = 'http://hogehoge.com/result/?kw=%s&pg=%d'
START_PAGE_NUMBER = 1
DISP_PER_PAGE     = 20  # 1Pに表示される件数
SLEEP_SEC         = 0.8 # リクエストごとに待機する秒数
ShopDB.create_table

# ---------------------------------
# スクレイプ実行
# ---------------------------------
all_shops = []
tdfk = Functions.get_tdfk
tdfk.each do |ken|
    # ------------------------------------------------------------
    # A 都道府県ループ
    # ------------------------------------------------------------
    puts "===================================="
    puts "START #{ken} FETCHING"
    puts "===================================="
    search_word = "#{ken} #{TARGET_WORD}".encode("Shift_JIS")
    # ---------------------------------
    # A初回のHTTPリクエスト（市区町村リストを取得する）
    # ---------------------------------
    request_uri = BASE_URL % [ URI.escape(search_word), START_PAGE_NUMBER ]
    puts "fetching %s ..." % request_uri
    charset = nil
    html = open(request_uri) do |f|
      charset = f.charset #文字種別を取得します。
      f.read              # htmlを読み込み変数htmlに渡します。
    end
    page = Nokogiri::HTML.parse(html, nil, charset) #htmlを解析し、オブジェクト化
    # 市区町村リストの取得
    cities = []
    page.css('#address_view .list-link-01 > li').each do |city|
        cities << city.text.match(/(.+)（/)[1]
    end
    p cities
    cities.each do |city|
        # ------------------------------------------------------------
        # B 都道府県 + 市区町村ループ
        # ------------------------------------------------------------
        puts "---------------"
        puts "START #{ken} > #{city} FETCHING"
        puts "---------------"
        search_word = "#{ken}#{city} #{TARGET_WORD}".encode("Shift_JIS")
        # ---------------------------------
        # B初回のHTTPリクエスト（最大ページ数を取得する）
        # ---------------------------------
        request_uri = BASE_URL % [ URI.escape(search_word), START_PAGE_NUMBER ]
        puts "fetching %s ..." % request_uri
        html = open(request_uri) do |f|
          charset = f.charset #文字種別を取得します。
          f.read              # htmlを読み込み変数htmlに渡します。
        end
        page = Nokogiri::HTML.parse(html, nil, charset)
        # 最大ページ数の算出
        count = page.css('.bottomNav span').text.match(/\/(\d+)件/)[1].to_s.to_i
        maxpage = count / DISP_PER_PAGE
        maxpage += 1 if (count % DISP_PER_PAGE) > 0

        # 最初のページに再度リクエストするのは無駄なのでこのまま解析する
        all_shops += Functions.page_per_parse(page, ken, city)
        puts "====> parsed %s" % request_uri

        # 残りのページの解析
        for pagenum in START_PAGE_NUMBER+1..maxpage do
            # ------------------------------------------------------------
            # C 都道府県 + 市区町村　＞　ページングループ
            # ------------------------------------------------------------
            # 実際にリクエストするURLの生成
            request_uri = BASE_URL % [ URI.escape(search_word), pagenum ]
            puts "fetching %s ..." % request_uri
            html = open(request_uri) do |f|
              charset = f.charset #文字種別を取得します。
              f.read              # htmlを読み込み変数htmlに渡します。
            end
            page = Nokogiri::HTML.parse(html, nil, charset)
            # 配列の合流
            all_shops += Functions.page_per_parse(page, ken, city)
            puts "====> parsed %s" % request_uri
            # 怒られないように待機する
            sleep SLEEP_SEC
        end

    end
end

# ---------------------------------
# DBへ保存
# ---------------------------------
ShopDB.insert_shops all_shops
puts "｡･:*+((((*o･ω･)o)))゜｡･:*+･+*:･｡゜(((o(･ω･o*))))+*:･｡"
puts "You Are All Complited!!"
puts "｡･:*+((((*o･ω･)o)))゜｡･:*+･+*:･｡゜(((o(･ω･o*))))+*:･｡"
