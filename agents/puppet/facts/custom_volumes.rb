Facter.add('custom_volumes') do
   setcode do
      if (File.exists?('/etc/custom_volumes.json'))
        JSON.parse(File.read('/etc/custom_volumes.json'))
      else
        Hash.new
      end
   end
end
