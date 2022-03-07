# frozen_string_literal: true

def versions
  {
    elrond: ENV['ELROND_VERSION'] || '1.2.38.2-rc2',
    cinc: '17.9.26',
    ubuntu: '20.04',
    oracle: '8.5'
  }
end
