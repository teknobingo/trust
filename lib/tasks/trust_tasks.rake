
namespace :db do
  DELEGATORS = [ :create, :drop, :migrate, :rollback, :setup ]
  DESCRIPTORS = Hash[*`cd test/dummy; rake -T`.split("\n").select{ |line| line =~ /^rake db:/ }.map{ |line| line.split('#').map{ |str| str.strip } }.flatten]

  DELEGATORS.each do |delegate|
    desc DESCRIPTORS["rake db:#{delegate}"]
    task delegate do
      system "cd test/dummy; rake db:#{delegate}"
    end
  end
end
