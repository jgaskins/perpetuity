require 'spec_helper'
require 'support/test_classes'

describe 'validations' do
  let(:car_mapper) { Perpetuity[Car] }

  it 'raises an exception when inserting an invalid object' do
    car = Car.new
    expect { car_mapper.insert car }.to raise_error
  end

  it 'does not raise an exception when validations are met' do
    car = Car.new
    car.make = "Volkswagen"
    expect { car_mapper.insert car }.not_to raise_error
  end
end
