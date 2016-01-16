class CreateShortenerTable < ActiveRecord::Migration
  def change
    create_table :shortener_shortened_urls do |t|
      # we can link this to a user for interesting things
      t.integer :owner_id
      t.string :owner_type, :limit => 20

      # we can link this to shortened object
      t.integer :item_id
      t.string :item_type, :limit => 40
      t.boolean :special, default: false

      # the real url that we will redirect to
      t.string :url, :null => false

      # the unique key
      t.string :unique_key, :limit => 10, :null => false

      # how many times the link has been clicked
      t.integer :use_count, :null => false, :default => 0

      t.timestamps
    end

    # we will lookup the links in the db by key, urls and owners.
    # also make sure the unique keys are actually unique
    add_index :shortener_shortened_urls, :unique_key, :unique => true
    add_index :shortener_shortened_urls, :url
    add_index :shortener_shortened_urls, [:owner_id, :owner_type]
    add_index :shortener_shortened_urls, [:item_id, :item_type, :special], name: 'index_shortener_shortened_urls_on_special_item'

    # tracking info
    create_table :shortener_shortened_clicks do |t|
      t.integer :shortened_url_id
      t.string :remote_ip
      t.string :referer
      t.string :agent
      t.string :country
      t.string :browser
      t.string :platform
      t.timestamps
    end
  end
end
