{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "__SERVICE_TITLE__ Configuration",
  "description": "Configuration for Managed __SERVICE_TITLE__",
  "type": "object",
  "required": ["tenant", "name"],
  "properties": {
    "tenant": {
      "type": "string",
      "description": "Owning tenant name",
      "pattern": "^([a-z][a-z0-9-]*)?$",
      "maxLength": 63
    },
    "name": {
      "type": "string",
      "description": "__SERVICE_TITLE__ instance name",
      "pattern": "^[a-z][a-z0-9-]*$",
      "minLength": 1,
      "maxLength": 63
    }
  }
}
