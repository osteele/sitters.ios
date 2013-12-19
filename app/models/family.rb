class Family
  include BW::KVO
  InitialDemoSitterCount = 6
  MaxSitterCount = 7

  attr_accessor :sitters
  attr_accessor :recommended_sitters

  def self.instance
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    resetSitterList

    # recompute once the sitter list has loaded
    observe(Sitter, :all) do
      resetSitterList if sitters.empty?
    end
  end

  def updateFrom(data)
    # save these in case the family sitter list comes in before the global sitter list has loaded
    @sitter_ids = data['sitter_ids']
    resetSitterList
  end

  def sitters=(sitters)
    return if @sitters == sitters

    self.willChangeValueForKey :sitters
    @sitters = sitters
    self.didChangeValueForKey :sitters

    self.willChangeValueForKey :recommended_sitters
    @recommended_sitters = nil
    self.recommended_sitters # for effect
    self.didChangeValueForKey :recommended_sitters
  end

  def recommended_sitters
    @recommended_sitters ||= Sitter.all - sitters
  end

  def setSitterCount(count)
    delta = count - self.sitters.length
    # don't update from the cloud once we've touched this locally
    @sitter_ids = nil unless delta == 0
    case
    when delta < 0 then self.sitters = self.sitters[0...count]
    when 0 < delta then self.sitters = self.sitters + self.recommended_sitters[0...delta]
    end
  end

  def canAddSitter(sitter)
    return self.sitters.length < MaxSitterCount && !self.sitters.include?(sitter)
  end

  def addSitter(sitter)
    return unless self.canAddSitter(sitter)
    # instead of <<, for KVO
    self.sitters = self.sitters + [sitter]
    # don't update from the cloud once we've touched this locally
    @sitter_ids = nil
  end

  private

  def resetSitterList
    self.sitters = if @sitter_ids
        @sitter_ids.map { |id| Sitter.findSitterById id }.reject(&:nil?)
      else
        self.sitters = Sitter.all[0...InitialDemoSitterCount]
      end
  end
end
