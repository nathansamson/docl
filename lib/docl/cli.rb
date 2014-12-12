class DOCL::CLI < Thor
    desc "authorize", "Authrorize docl to read / modify your DO info"
    def authorize
        puts "You'll need to enter your DigitalOcean Private Access Token."
        puts "To be able to create / modify droplets, it needs to be read / write."
        puts "You can create a token on the DO website vite the Apps & API menu."

        print "Enter your DO Token: "
        token = $stdin.gets.chomp

        f = File.open(config_path, 'w')
        f.write(token)
        f.close
        File.chmod(0600, config_path)
    end

    desc "images", "List all images"
    method_option :public, type: :boolean, default: false, aliases: '-p'
    def images()
        images = barge.image.all.images
        images = images.select { |image| image.public == options.public }
        images = images.sort { |a, b| a.name <=> b.name }
        images.each do |image|
            if !image.slug.nil?
                puts "#{image.name} (#{image.slug}, id: #{image.id})"
            else
                puts "#{image.name} (id: #{image.id})"
            end
        end
    end

    desc "keys", "List all keys"
    def keys()
        barge.key.all.ssh_keys.each do |key|
            puts "#{key.name} (id: #{key.id})"
        end
    end

    desc "regions", "List regions"
    method_option :metadata, type: :boolean, default: false
    method_option :private_networking, type: :boolean, default: false
    method_option :backups, type: :boolean, default: false
    method_option :ipv6, type: :boolean, default: false
    def regions()
        regions = barge.region.all.regions
        regions = regions.select do |region|
            if options.ipv6 && !region.features.include?('ipv6')
                next false
            end

            if options.metadata && !region.features.include?('metadata')
                next false
            end

            if options.private_networking && !region.features.include?('private_networking')
                next false
            end

            if options.backups && !region.features.include?('backups')
                next false
            end

            next true
        end
        regions.sort { |a, b| a.name <=> b.name }.each do |region|
            puts "#{region.name} (#{region.slug})"
        end
    end

    desc "create [name] [image] [size] [region]", "Create a droplet"
    method_option :key, type: :string, default: nil
    method_option :user_data, type: :string, default: nil
    method_option :private_networking, type: :boolean, default: true
    method_option :enable_backups, type: :boolean, default: false
    method_option :ipv6, type: :boolean, default: false
    method_option :wait, type: :boolean, default: false
    def create(name, image, size, region)
        call_options = {
            name: name,
            image: image,
            region: region,
            size: size,
            private_networking: options.private_networking,
            enable_backups: options.enable_backups,
            ipv6: options.ipv6,
        }
        if options[:key]
            call_options[:ssh_keys] = [options[:key]]
        end
        if options.user_data
            call_options[:user_data] = File.read(options.user_data)
        end

        response = barge.droplet.create(call_options)
        if response.id == 'unprocessable_entity'
            puts response.message
            exit(1)
        end

        if options.wait
            print "Waiting for droplet to become available"
            action_link = response.links.actions.first
            begin
                print '.'
                sleep 1
                action = barge.action.show(action_link.id).action
            end until action.status != 'in-progress'
            puts "Completed"

            puts "You can connect to your Droplet via"
            droplet = barge.droplet.show(response.droplet.id).droplet
            ip_addresses(droplet).each(&method(:puts))
        end
    end

    private
    def config_path
        File.expand_path('~/.docl-access-token')
    end

    def barge
        if !File.exist?(config_path)
            puts 'Please run docl authorize first.'
            exit(1)
        end

        @barge ||= Barge::Client.new(access_token: File.read(config_path))
    end

    def ip_addresses(droplet)
        network_types = [droplet.networks.v4]
        network_types << droplet.networks.v6 if droplet.networks.v6

        network_types.flatten.select { |nw| nw.type == 'public' }.map { |nw| nw.ip_address }
    end
end
