const getPlacementConstraints = (placement) => {
  if (!placement) return []; // TODO(@tylermenezes) Figure out what format this should be in
  const constraints = [];

  if (placement.type === 'unique') constraints.push({
    Operator: 'distinct_hosts',
    Value: true,
  });

  if (placement.os_type) constraints.push({
    Attribute: '${attr.kernel.name}',
    Value: placement.os_type,
  });

  if (placement.os) constraints.push({
    Attribute: '${attr.os.name}',
    Value: placement.os,
  });

  if (placement.os_version) constraints.push({
    Attribute: '${attr.os.version}',
    Value: placement.os_version,
  });

  return constraints;
}

module.exports = (vars) => [ ...getPlacementConstraints(vars.placement), ...(vars.constraints || []) ];
