# coding: utf-8
module ShopDB
    require "sqlite3"

    # テーブルの作成
    def self.create_table()
        db  = SQLite3::Database.new 'data.db'
        sql = <<-SQL
            CREATE TABLE shops(
                id      integer primary key autoincrement,
                name    text,
                catch   text,
                address text,
                zip     varchar(8),
                tdfk    integer,
                city    varchar(10),
                tel     varchar(20)
            );
            CREATE INDEX index_name ON shops(name);
            CREATE INDEX index_tdfk ON shops(tdfk);
            CREATE INDEX index_city ON shops(city);
        SQL
        db.execute_batch sql
        db.close
    end

    # データの挿入
    def self.insert_shops(all_shop_data)
        db  = SQLite3::Database.new 'data.db'
         #トランザクションによる値の挿入
        db.transaction do
            # ループ回してすべて一括挿入
            all_shop_data.each do |values|
                sql = "insert into shops(name, catch, address, zip, tdfk, city, tel) values (:name, :catch, :address, :zip, :tdfk, :city, :tel)"
                db.execute(sql, values)
            end
        end
        db.close
    end
end
