class Family
  InitialSitterCount = 6
  MaxSitterCount = 7

  attr_accessor :sitters
  attr_accessor :suggested_sitters

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def sitters
    @sitters ||= Sitter.all[0...InitialSitterCount]
  end

  def sitters=(sitters)
    self.willChangeValueForKey :sitters
    @sitters = sitters
    self.didChangeValueForKey :sitters

    self.willChangeValueForKey :suggested_sitters
    @suggested_sitters = nil
    self.suggested_sitters # for effect
    self.didChangeValueForKey :suggested_sitters
  end

  def suggested_sitters
    @suggested_sitters ||= Sitter.all - @sitters
  end

  def setSitterCount(count)
    delta = count - self.sitters.length
    case
    when delta < 0 then self.sitters = self.sitters[0...count]
    when 0 < delta then self.sitters = self.sitters + self.suggested_sitters[0...delta]
    end
  end

  def canAddSitter(sitter)
    return self.sitters.length < MaxSitterCount && !self.sitters.include?(sitter)
  end

  def addSitter(sitter)
    return unless self.canAddSitter(sitter)
    # instead of <<, for KVO
    self.sitters = self.sitters + [sitter]
  end
end
