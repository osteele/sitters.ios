class Storage
  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def database
    @db ||= begin
      cachesDirectoryURL = NSFileManager.defaultManager.URLsForDirectory(NSCachesDirectory, inDomains:NSUserDomainMask).first
      cacheDbURL = cachesDirectoryURL.URLByAppendingPathComponent('cache.db')
      puts "cache = #{cacheDbURL.path}"
      db = FMDatabase.databaseWithPath(cacheDbURL.path)
      db.open
      db.executeUpdate <<-SQL
        CREATE TABLE json_cache (
            key VARCHAR(50) PRIMARY KEY
          , version INT
          , json TEXT
          , updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
          , UNIQUE(key));
      SQL
      db
    end
  end

  def firebaseEnvironment
    UIApplication.sharedApplication.delegate.firebaseEnvironment
  end

  def withJSONCache(cacheKey, version:cacheVersion, &block)
    data = fetchDataForKey(key, version:cacheVersion)
    if not data and block
      data = block.call
      storeData data, key:cacheKey, version:cacheVersion
    end
    return data
  end

  def fetchDataForKey(cacheKey, version:cacheVersion)
    db = self.database
    results = db.executeQuery(<<-SQL, withArgumentsInArray:[cacheKey, cacheVersion])
      SELECT json FROM json_cache WHERE key=? AND version=?;
    SQL
    if results.next
      json = results.dataNoCopyForColumn(:json)
      error = Pointer.new(:id)
      data = NSJSONSerialization.JSONObjectWithData(json, options:0, error:error)
      NSLog error[0].description if error[0]
      data = nil if error[0]
    end
    return data
  end

  def storeData(data, key:cacheKey, version:cacheVersion)
    db = self.database
    throw "storeData: data is nil" if data.nil?
    json = BW::JSON.generate(data)
    values = { key: cacheKey, version: cacheVersion, json: json }
    db.executeUpdate <<-SQL, withParameterDictionary:values
      INSERT OR REPLACE INTO json_cache (key, version, json, updated_at) VALUES (:key, :version, :json, CURRENT_TIMESTAMP);
    SQL
  end

  def onCachedFirebaseValue(path, options={}, &block)
    cacheKey = options[:cacheKey] || path
    cacheVersion = options[:cacheVersion] || 1
    data = UseCache && fetchDataForKey(cacheKey, version:cacheVersion)
    previous_json = nil
    if data
      previous_json = BW::JSON.generate(data)
      NSLog "Cache hit: %@", path
      Dispatch::Queue.main.async do
        block.call data
      end
    else
      NSLog "Cache miss: %@", path
    end
    NSLog "Subscribing to %@", firebaseEnvironment[path]
    firebaseEnvironment[path].on(:value) do |snapshot|
      data = snapshot.value
      if data and (not previous_json or previous_json != BW::JSON.generate(data))
        NSLog "Subscription: %@", path
        storeData data, key:cacheKey, version:cacheVersion
        block.call data
      end
      previous_json = nil
    end
  end

  private

  UseCache = true
end
