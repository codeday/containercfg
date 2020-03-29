module.exports.getTemplates = (task) => {
  if (!(task.vault && task.vault.files)) return [];
  const keys = Object.keys(task.vault.files)
    .map((key) => ({ key, files: task.vault.files[key] }))
    .map((key) => Object.keys(key.files)
      .map((fileName) => ({ key: key.key, fileName, ...key.files[fileName] }))
    )
    .reduce((a, b) => [...a, ...b], [])
    .map((file) => ({
      SourcePath: '',
      DestPath: `local/${file.fileName}`,
      EmbeddedTmpl: `{{- with secret "kv/data/${file.key}" -}}${file.contents}{{ end }}`,
      ChangeMode: 'restart',
      ChangeSignal: '',
      Perms: '0644',
      LeftDelim: '{{',
      RightDelim: '}}',
      Envvars: file.env,
    }));
  return keys;
}

module.exports.getEnvTemplate = (task) => {
  if (!(task.vault && task.vault.env)) return [];

  return module.exports.getTemplates({ vault: { files:
    Object.keys(task.vault.env)
      .map((key) => ({
        key,
        files: {
          "secrets.env": {
            env: true,
            contents: Object.keys(task.vault.env[key]).map((envKey) => `${envKey}={{ .Data.data.${task.vault.env[key][envKey]} }}`).join("\n"),
          }
        }
      }))
      .reduce((a, b) => { a[b.key] = b.files; return a; }, {})
    }});
}
