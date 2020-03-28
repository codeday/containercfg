const getTags = (port, taskName, jobName) => {
  const { lb, scheme } = port;
  const tags = [];
  const service = `${jobName}-${taskName}-${port.name}`;
  const serviceTls = `${service}-tls`;

  const hostRule = (Array.isArray(lb.domain) ? lb.domain : [lb.domain])
    .map((domain) => `Host(\`${domain}\`)`)
    .join(' || ');

  tags.push(`traefik.http.routers.${service}.rule=${hostRule}`);
  tags.push(`traefik.enable=true`);

  if (scheme === 'https') tags.push(`traefik.http.services.${service}.loadbalancer.server.scheme=https`);
  if (lb.https_only) tags.push(`traefik.http.routers.${service}.middlewares=redirect-scheme@file`);

  if (lb.middleware) tags.push(`traefik.http.routers.${service}.middlewares=${lb.middleware.join(',')}`);
  if (lb.middleware && lb.cert) tags.push(`traefik.http.routers.${serviceTls}.middlewares=${lb.middleware.join(',')}`);

  if (lb.cert) {
    tags.push(
      `traefik.http.routers.${serviceTls}.rule=${hostRule}`,
      `traefik.http.routers.${serviceTls}.tls=true`,
      `traefik.http.routers.${serviceTls}.tls.certresolver=${lb.cert.replace('.', '-')}`,
      `traefik.http.routers.${serviceTls}.tls.domains[0].main=*.${lb.cert}`,
      `traefik.http.routers.${serviceTls}.tls.domains[0].sans=${lb.cert}`
    );
  }

  if (lb.sticky) {
    tags.push(
      `traefik.http.services.${service}.loadBalancer.sticky=true`,
      `traefik.http.services.${service}.loadBalancer.sticky.cookie.name=${service}`,
      `traefik.http.services.${service}.loadBalancer.sticky.cookie.secure=false`,
      `traefik.http.services.${service}.loadBalancer.sticky.cookie.httpOnly=true`
    );
  } else {
    tags.push(`traefik.http.services.${service}.loadBalancer.sticky=false`);
  }

  return tags;
}

const getName = (jobName, taskName, portName) => {
  const result = [ jobName ];
  if (taskName !== jobName) result.push(taskName);
  if (portName !== result[result.length - 1]) result.push(portName);
  return result.join('-');
}

module.exports = (task, jobName) => {
  if (!task.ports) return [];
  return Object.keys(task.ports)
    .map((name) => ({ name, ...task.ports[name]}))
    .map((port) => ({
      Name: getName(jobName, task.name, port.name),
      PortLabel: port.name,
      AddresssMode: 'auto',
      CanaryTags: [ "traefik.enable=false" ],
      Tags: [
        `scheme=${port.scheme || 'http'}`,
        ...(port.lb ? getTags(port, task.name, jobName) : []),
        ...(port.tags || []),
      ]
    }))

}
