require 'perpetuity/validations'

describe Perpetuity::ValidationSet do
  it 'contains validations' do
    subject.validations.should_not be_nil
  end
end

describe Perpetuity::Validation do

end
