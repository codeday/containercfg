Facter.add('private_interface') do
   setcode do
      sel_interface = "eth0"
      if (File.exists?('/etc/private_interface.txt'))
        sel_interface = File.read('/etc/private_interface.txt').strip
      end

      iface = Facter.value(:networking)['interfaces'][sel_interface]
      iface['name'] = sel_interface
      iface
   end
end
