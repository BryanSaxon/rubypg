require './record'

class User < Record
  scope :bryan, -> { where(name: 'Bryan') }
  scope :kevin, -> { where(name: 'Kevin') }
end
