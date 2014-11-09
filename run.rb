$stdout.sync

require 'net/http'
require 'nokogiri'
require 'fileutils'

distro = 'ubuntu'
version = $*[0] # f.e. 3.17.2
type = $*[1] || 'generic' # generic | lowlatency
architecture = $*[2] || 'amd64' # i386 | amd64
r = Regexp.new("#{type}_.*_#{architecture}$")
if version
  puts "Searching kernel #{version} #{type} for #{architecture} on kernel.ubuntu.com/~kernel-ppa/mainline/"
else
  puts 'Available versions:'
end

content1 = Net::HTTP.get('kernel.ubuntu.com', '/~kernel-ppa/mainline/')
doc1 = Nokogiri::HTML(content1)
doc1.css('body a').each do |a1|
  a1.content.strip.scan(/\Av(.*)\-[a-z]+\/?\z/) do |k1|
    if version
      if k1.flatten.first == version
        url = "/~kernel-ppa/mainline/#{a1['href']}"
        links = []
        content2 = Net::HTTP.get('kernel.ubuntu.com', url)
        doc2 = Nokogiri::HTML(content2)
        doc2.css('body a').each do |a2|
          a2['href'].strip.scan(/\Alinux-(?:image|headers)-(.*)\.deb\z/) do |k2|
            links.push("http://kernel.ubuntu.com#{url}#{a2['href']}") if k2.first =~ /_all$/ || k2.first =~ r
          end
        end
        dir = File.join(Dir.pwd, "#{distro}_#{version}_#{type}_#{architecture}")
        links.each do |link|
          f = link.split('/').last
          tf = File.join(dir, f)
          FileUtils.mkdir_p dir
          if File.exist? tf
            puts "#{f} already exists"
          else
            `axel -o "#{tf}" "#{link}"`
            puts "Got #{f}"
          end
        end
        puts "Deb files placed in #{dir}"
        exit
      end
    else
      puts k1
    end
  end
end

puts "Could not find version #{version}"