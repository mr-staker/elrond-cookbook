# frozen_string_literal: true

def versions
  elrond_test = '1.3.36.0'

  {
    elrond: ENV['ELROND_VERSION'] || elrond_test,
    cinc: '17.9.26',
    ubuntu: '20.04',
    oracle: '8.6'
  }
end
