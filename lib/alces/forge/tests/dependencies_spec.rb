require 'rspec'
require 'alces/forge/dependencies'
require 'alces/forge/package_metadata'

describe 'Dependencies' do
  class FakeApi
    def packages
      @packages ||= {}
    end

    def register(pkg)
      packages[pkg['id']] = pkg
    end

    def get(url)
      return {
          'data' => packages[id_from_url(url)]
      }
    end

    private

    def id_from_url(url)
      match = /packages\/(?<id>[0-9a-f\-]+)\//.match(url)
      match ? match['id'] : nil
    end
  end

  def package(pkg_id, deps=[])
    return {
      'id' => pkg_id,
      'attributes' => {
        'name' => pkg_id
      },
      'relationships' => {
        'dependencies' => {
          'data' => deps.map { |d| {'id' => d} }
        }
      }
    }
  end

  def expect_packages(packages)
    expect(
      packages.map { |p| p.id}
    )
  end

  it 'should resolve without dependencies correctly' do
    pkg_a = package('a')

    fake_api = FakeApi.new
    fake_api.register(pkg_a)

    actual = Alces::Forge::Dependencies.resolve(fake_api, Alces::Forge::PackageMetadata.new(pkg_a))

    expect_packages(actual).to eq(['a'])
  end

  it 'should resolve simple dependencies correctly' do
    pkg_b = package('b')
    pkg_a = package('a', ['b'])

    fake_api = FakeApi.new
    fake_api.register(pkg_b)
    fake_api.register(pkg_a)

    expect_packages(Alces::Forge::Dependencies.resolve(fake_api,  Alces::Forge::PackageMetadata.new(pkg_a))).to eq(
       ['b', 'a']
     )
  end

  it 'should resolve transitive dependencies correctly' do
    pkg_c = package('c')
    pkg_b = package('b', ['c'])
    pkg_a = package('a', ['b'])

    fake_api = FakeApi.new
    fake_api.register(pkg_c)
    fake_api.register(pkg_b)
    fake_api.register(pkg_a)

    expect_packages(Alces::Forge::Dependencies.resolve(fake_api,  Alces::Forge::PackageMetadata.new(pkg_a))).to eq(
       ['c', 'b', 'a']
     )
  end

  it 'should order dependencies correctly when required multiple times' do
    pkg_c = package('c')
    pkg_b = package('b', ['c'])
    pkg_a = package('a', ['c', 'b'])
    # The test here is that 'c' is installed before 'b' even though it's resolved first

    fake_api = FakeApi.new
    fake_api.register(pkg_c)
    fake_api.register(pkg_b)
    fake_api.register(pkg_a)

    expect_packages(Alces::Forge::Dependencies.resolve(fake_api,  Alces::Forge::PackageMetadata.new(pkg_a))).to eq(
       ['c', 'b', 'a']
     )
  end

  it 'should handle cyclic dependencies' do
    # This is probably not what we actually want - but it does at least document how we handle this scenario presently
    pkg_b = package('b', ['a'])
    pkg_a = package('a', ['b'])

    fake_api = FakeApi.new
    fake_api.register(pkg_b)
    fake_api.register(pkg_a)

    expect_packages(Alces::Forge::Dependencies.resolve(fake_api,  Alces::Forge::PackageMetadata.new(pkg_a))).to eq(
       ['b', 'a']
     )
  end
end
