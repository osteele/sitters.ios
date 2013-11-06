def die(message)
  STDERR.puts message
  exit 1
end

class << ENV
  def require(name)
    self[name] or die("The #{name} environment variable is required")
  end
end
