require 'thor'
require 'barge'

class DOCL < Thor
    desc "images", "List all images"
    method_option :public, type: :boolean, default: false, aliases: '-p'
    def images()
        barge.image.all.images.select { |image| image.public == options.public } .each do |image|
            puts "#{image.name} (id: #{image.id})"
        end
    end

    desc "keys", "List all keys"
    def keys()
        barge.key.all.ssh_keys.each do |key|
            puts "#{key.name} (id: #{key.id})"
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
        puts call_options

        response = barge.droplet.create(call_options)
        puts response

        if options.wait
            print "Waiting for droplet to become available"
            action_link = response.links.actions.first
            begin
                print '.'
                sleep 1
                action = barge.action.show(action_link.id).action
            end until action.status != 'in-progress'
            puts "Completed"
        end
    end

    private
    def barge
        @barge ||= Barge::Client.new(access_token: 'fe05cfe7139b010a4606d0bda434c1a8ffef67dffa33d303a24d3b9e35a2c2fd')
    end
end