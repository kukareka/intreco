namespace :janus do
  task :create_room, [:room] => :environment do |_, args|
    pp JanusClient.new.create_room(args[:room])
  end

  task :list_rooms, [:room] => :environment do |_, args|
    pp JanusClient.new.list_rooms
  end
end
