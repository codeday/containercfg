const splitImage = (image) => {
  const lastIndex = image.lastIndexOf(':');
  return [ image.substr(0, lastIndex), image.substr(lastIndex + 1)];
}

const parsePreviousJob = (jobInfo) => {
  // Convert each group to K=>V object (instead of an array) and provide count + task info.
  const groupsOut = {};
  jobInfo.TaskGroups.forEach((group) => {

    // Also convert each task to K=>V and provide repo + image for Docker containers.
    const tasksOut = {};
    group.Tasks.forEach((task) => {

      // Only Docker containers have an image. All other tasks won't return any info.
      if (task.Driver === 'docker') {
        const [ repo, tag ] = splitImage(task.Config.image);
        tasksOut[task.Name] = {
          repo,
          tag,
        };
      }
    });

    groupsOut[group.Name] = {
      count: group.Count,
      tasks: tasksOut,
    };
  });

  return groupsOut;
}

module.exports = (job, previousJob) => {
  if (!job.TaskGroups || !previousJob.TaskGroups) return job;
  const defaultVars = parsePreviousJob(previousJob);

  // Overwrite count for each group which already has a running count.
  job.TaskGroups = job.TaskGroups.map((group) => {
    if (!(group.Name in defaultVars)) return group;
    const defaultVarsGroup = defaultVars[group.Name];

    if (defaultVarsGroup.count) group.count = defaultVarsGroup.count;

    if (!group.Tasks) return group;

    // Overwrite image tag for each Docker task with the same specified repo.
    group.Tasks = group.Tasks.map((task) => {
      if (!(task.Name in defaultVarsGroup.tasks)) return task;
      const defaultVarsTask = defaultVarsGroup.tasks[task.Name];

      if (task.Driver === 'docker') {
        const [ repo, tag ] = splitImage(task.Config.image);
        if (defaultVarsTask.repo && defaultVarsTask.tag && defaultVarsTask.repo === repo) {
          task.Config.image = `${repo}:${defaultVarsTask.tag}`;
        }
      }

      return task;
    });

    return group;
  });

  return job;
}
