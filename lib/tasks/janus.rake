namespace :janus do
  task :create_room, [:room] => :environment do |_, args|
    pp JanusClient.new.create_room(args[:room])
  end

  task list_rooms: :environment do |_, args|
    pp JanusClient.new.list_rooms
  end

  # TODO : Please consider this code as a PoC pasta that definitely requires a complete refactoring
  task :create_video, [:interview] => :environment do |_, args|
    interview = Interview.find_by!(name: args[:interview])
    room_id = interview.room_id
    # TODO: add audio and candidate later on
    files = Dir["janus/recordings/room-#{room_id}-expert-*-video.mjr"].map do |path|
      file = File.basename(path, ".*")
      mjr_output = %x{ docker-compose exec parser janus-pp-rec /recordings/#{file}.mjr /recordings/#{file}.webm }
      start_at = mjr_output.match(/Written: (\d*)/)[1].to_d / 1e6

      puts "Resizing #{file}"
      %x{ ffmpeg -i janus/recordings/#{file}.webm -filter_complex "
        [0:v]scale=640x480[out]" -map '[out]' janus/recordings/#{file}-resized.webm}

      ffprobe_output = %x{ ffprobe -v quiet -print_format json -show_format janus/recordings/#{file}-resized.webm }
      duration = JSON.parse(ffprobe_output)['format']['duration'].to_d

      {
        file: file,
        start_at: start_at,
        end_at: start_at + duration
      }
    end.sort_by { |f| f[:start_at] }

    ffmpeg_inputs = files.map { |f| "-i janus/recordings/#{f[:file]}-resized.webm" }

    blanks = files.each_cons(2).with_index.map do |(f1, f2), i|
      "color=black:s=640x480:d=#{f2[:start_at] - f1[:end_at]}[b#{i}];\n"
    end

    concat_inputs = (0...files.length).map{ |i| "#{i}:v" }.zip((0...blanks.length).map{ |i| "b#{i}" }).flatten.compact.map { |i| "[#{i}]" }

    ffmpeg_cmd = %{ ffmpeg #{ffmpeg_inputs.join(' ')} -filter_complex "
      #{blanks.join}
    #{concat_inputs.join}concat=n=#{concat_inputs.length}[out]" -map '[out]' janus/recordings/room-#{room_id}-expert-merged.webm }

    puts "Merging: #{ffmpeg_cmd}"

    %x{#{ffmpeg_cmd}}
  end
end
