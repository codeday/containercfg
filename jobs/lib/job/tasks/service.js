const { strToNs } = require('../../time');

const getRouterTags = (name, taskName, jobName, scheme, lb) => {
  const tags = [];
  const domainName = lb.domain.replace(/\./g, '-');
  const service = `${jobName}-${taskName}-${name}-${domainName}`;
  const serviceTls = `${service}-tls`;

  const hostRule = `Host(\`${lb.domain}\`)`;
  tags.push(
    `traefik.http.routers.${service}.rule=${hostRule}`,
    `traefik.http.middlewares.${service}-add-info.headers.customresponseheaders.X-Job=${jobName}`,
    `traefik.http.middlewares.${service}-add-info.headers.customresponseheaders.X-Task=${taskName}`,
    `traefik.http.middlewares.${service}-add-info.headers.customresponseheaders.X-Service=${name}`,
  );

  let middleware = [...(lb.middleware || []), `${service}-add-info`];

  if (scheme === 'https') tags.push(`traefik.http.services.${service}.loadbalancer.server.scheme=https`);
  if (lb.https_only) middleware = [ ...middleware, 'redirect-scheme@file' ];

  tags.push(`traefik.http.routers.${service}.middlewares=${middleware.join(',')}`);
  if (lb.cert) tags.push(`traefik.http.routers.${serviceTls}.middlewares=${middleware.join(',')}`);

  if (lb.cert) {
    tags.push(
      `traefik.http.routers.${serviceTls}.rule=${hostRule}`,
      `traefik.http.routers.${serviceTls}.tls=true`,
      `traefik.http.routers.${serviceTls}.tls.certresolver=${lb.cert.replace('.', '-')}`,
      `traefik.http.routers.${serviceTls}.tls.domains[0].main=*.${lb.cert}`,
      `traefik.http.routers.${serviceTls}.tls.domains[0].sans=${lb.cert}`
    );
  }

  return tags;
}

const getServiceTags = (name, taskName, jobName, lb) => {
  if (!lb) return [];
  const tags = [];
  const service = `${taskName}-${jobName}-${name}`;
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

const dedupTags = (tags) => {
  const hash = tags
    .reduce((a, b) => {
      const [ k, v ] = b.split('=', 2);
      a[k] = v;
      return a;
    }, {});

  return Object.keys(hash)
    .map((k) => `${k}=${hash[k]}`);
}

const getChecks = (jobName, taskName, portName, check) => (typeof check === 'undefined' ? [] : [{
  Name: `${jobName}_${taskName}_${portName}`,
  Type: 'http',
  PortLabel: portName,
  Method: (check || {}).method || "GET",
  Path: (check || {}).path || "/",
  Interval: strToNs((check || {}).interval || "1m"),
  Timeout: strToNs((check || {}).timeout || "10s"),
  CheckRestart: {
    Limit: (check || {}).failLimit || 3,
    Grace: strToNs((check || {}).failGrace || (check || {}).interval || "1m"),
  },
  Header: {
    Host: [ (check || {}).host || 'localhost' ],
  },
}]);

module.exports = (task, jobName) => {
  if (!task.ports) return [];
  return Object.keys(task.ports)
    .map((name) => ({ name, ...task.ports[name]}))
    .map((port) => ({
      Name: getName(jobName, task.name, port.name),
      PortLabel: port.name,
      AddresssMode: 'auto',
      CanaryTags: [ "canary=true" ],
      Checks: getChecks(jobName, task.name, port.name, port.check),
      Tags: dedupTags([
        `scheme=${port.scheme || 'http'}`,
        (port.lb && port.lb ? 'traefik.enable=true' : 'traefik.enable=false'),
        ...getServiceTags(port.name, task.name, jobName, port.lb),
        ...(port.lb ? (
            (Array.isArray(port.lb) ? port.lb : [port.lb])
              .map((lb) => getRouterTags(port.name, task.name, jobName, port.scheme, lb))
              .reduce((a, b) => [...a, ...b], [])
          ) : []),
        ...(port.tags || []),
      ])
    }))

}
