EatMe.func.yamlToJson =
  (yaml)=> {
    json = YAML.parse(yaml);
    json = JSONPC.stringify(json)
      .replace(/^(\ *[\{\[])\n/mg, '$1')
      .replace(/([\}\]])[\ \n]+([\]\}])/g, '$1$2');
    return json;
  };

config = `\
name: yaml-json
html: bootstrap
pane:
- name: YAML
  func: yamlToJson
  next: json
- name: JSON
  tabs:
  - name: Output
  - name: Errors
`;

$(() => {
  EatMe.configure(YAML.parse(config));
  EatMe.initialize();
});
