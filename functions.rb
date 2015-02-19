# coding: utf-8
module Functions
    # JP-01 北海道
    # JP-47 沖縄県
    TODOFUKEN         = %w(北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県 新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県 鳥取県 島根県 岡山県 広島県 山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県)

    # 都道府県の配列返すだけ。モジュールで直接変数の参照仕方がわからん
    def self.get_tdfk()
        TODOFUKEN
    end

    # 都道府県配列からISOのコードと対になるハッシュを作成
    def self.create_iso_hash()
        tdfk_iso_hash = {}
        TODOFUKEN.each_with_index do |ken, i|
            tdfk_iso_hash[ken.to_sym] = i+1
        end
        tdfk_iso_hash
    end

    # @param  [Nokogiri::HTML] page
    # @return [Array] ページに載っている店を配列にしたもの
    def self.page_per_parse (page, tdfk, city)
        shopdata = page.css('.normalResultsBox')
        # マージ用配列
        shops = []
        # (1):name, (2):catch, (3):address, (4):zip, (5):tdfk, (6):city, (7):tel
        shopdata.each do |sec|
            tmp = {}
            # (1) name
            tmp[:name] = sec.css('h4 a').text
            # (2) catch
            tmp[:catch] = sec.css('.iconLinks + p').text
            # その他のデータ（全部クラス・IDなしのp（怒））
            p_list = sec.css('p')
            p_list.each do |line|
                if line.text.include? "住所"
                    # (3) 元のフル住所
                    # 「住所 〒273-0011　千葉県船橋市湊町３丁目６−２３ 地図・ナビ」
                    # ====> 〒289-2522千葉県旭市足川３９０５
                    base_text = line.text.gsub('住所', '').gsub('地図・ナビ', '').gsub("\n", '').strip
                    tmp[:address] = base_text
                    # (4) 郵便番号
                    tmp[:zip]     = base_text.match( /\d{3}-\d{4}/ ).to_s
                    # (5) 都道府県
                    tdfk_iso_hash = create_iso_hash()
                    tmp[:tdfk] = tdfk_iso_hash[tdfk.to_sym]
                    # (6) 市区町村
                    tmp[:city]  = city
                end
                # (7) TEL
                if line.text.include? "TEL"
                    tmp[:tel] = line.text.gsub('TEL', '').gsub('F兼', '').gsub('(代)', '').gsub(' ', '').gsub("\n", '').strip unless line.text.include? "F専"
                end
            end
            # ひとつの店舗の情報を格納
            shops << tmp
        end
        shops
    end

end
