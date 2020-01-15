require "net/http"
require "json"
require "facter"

def get_url_json(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Metadata'] = 'true'
  response = http.request(request)
  JSON.parse(response.body)
end

Facter.add('host_volumes') do
  setcode do
    metadata = get_url_json('http://169.254.169.254/metadata/instance?api-version=2019-08-15')
    name = metadata['compute']['name']
    group = metadata['compute']['resourceGroupName']
    Facter::Core::Execution.exec('az login -i')
    vm_disks_raw = JSON.parse(Facter::Core::Execution.exec("az vm show -d -g #{group} -n #{name} --query 'storageProfile.dataDisks[]'"))
    disks_out = Hash.new

    for disk in vm_disks_raw;
      disk_id = disk['managedDisk']['id']
      lun = disk['lun']

      disk_info = JSON.parse(Facter::Core::Execution.exec("az disk show --ids '#{disk_id}'"))
      vol_tag = disk_info['tags']['volume']

      if vol_tag.nil? || vol_tag.empty?
        next
      end

      disks_out[vol_tag] = "/dev/disk/azure/scsi1/lun#{lun}"
    end

    disks_out
  end
end
