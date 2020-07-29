Facter.add('nomad_env') do
   setcode do
      if (File.exists?('/etc/nomad.env'))
        s = File.read('/etc/nomad.env')
        Hash[s.split("\n").map {|str| str.split("=")}]
      else
        {}
      end
   end
end
