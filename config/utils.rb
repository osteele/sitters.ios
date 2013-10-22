def die(message)
  STDERR.puts message
  exit 1
end

class << ENV
  def require(name)
    return ENV[name]
  catch IndexError
    die "The #{name} environment variable is required"
  end
end
