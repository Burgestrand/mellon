describe Mellon::Keychain do
  let(:keychain_path) do
    path = File.expand_path("../test_keychain.keychain", __dir__)
  end

  subject(:keychain) do
    Mellon::Keychain.new(keychain_path)
  end

  specify "#name" do
    keychain.name.should eq "test_keychain"
  end

  specify "#path" do
    keychain.path.should eq keychain_path
  end
end
