sofia.lemarc.fr : {
  "openapi": "3.1.0",
  "info": {
    "title": "Sofia Wind Farm API",
    "version": "0.1.0"
  },
  "paths": {
    "/pn/date-range": {
      "get": {
        "tags": [
          "PN"
        ],
        "summary": "Pn Date Range",
        "operationId": "pn_date_range_pn_date_range_get",
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/PnDateRange"
                }
              }
            }
          }
        }
      }
    },
    "/pn/latest-settlement-period": {
      "get": {
        "tags": [
          "PN"
        ],
        "summary": "Pn Latest Settlement",
        "operationId": "pn_latest_settlement_pn_latest_settlement_period_get",
        "parameters": [
          {
            "name": "bmu_id",
            "in": "query",
            "required": false,
            "schema": {
              "anyOf": [
                {
                  "type": "string"
                },
                {
                  "type": "null"
                }
              ],
              "title": "Bmu Id"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/PnLatestSettlementPeriod"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/pn/refresh": {
      "post": {
        "tags": [
          "PN"
        ],
        "summary": "Force Refresh Pn",
        "operationId": "force_refresh_pn_pn_refresh_post",
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {

                }
              }
            }
          }
        }
      }
    },
    "/pn/{bmu_id}": {
      "get": {
        "tags": [
          "PN"
        ],
        "summary": "Get Pn",
        "operationId": "get_pn_pn__bmu_id__get",
        "parameters": [
          {
            "name": "bmu_id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string",
              "title": "Bmu Id"
            }
          },
          {
            "name": "time_from",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string",
              "format": "date-time",
              "title": "Time From"
            }
          },
          {
            "name": "time_to",
            "in": "query",
            "required": true,
            "schema": {
              "type": "string",
              "format": "date-time",
              "title": "Time To"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": {
                    "$ref": "#/components/schemas/PnResponse"
                  },
                  "title": "Response Get Pn Pn  Bmu Id  Get"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/remit": {
      "get": {
        "tags": [
          "REMIT"
        ],
        "summary": "List Remits",
        "operationId": "list_remits_remit_get",
        "parameters": [
          {
            "name": "bmu_id",
            "in": "query",
            "required": false,
            "schema": {
              "anyOf": [
                {
                  "type": "string"
                },
                {
                  "type": "null"
                }
              ],
              "title": "Bmu Id"
            }
          },
          {
            "name": "event_status",
            "in": "query",
            "required": false,
            "schema": {
              "anyOf": [
                {
                  "type": "string"
                },
                {
                  "type": "null"
                }
              ],
              "title": "Event Status"
            }
          },
          {
            "name": "limit",
            "in": "query",
            "required": false,
            "schema": {
              "type": "integer",
              "maximum": 500,
              "default": 100,
              "title": "Limit"
            }
          },
          {
            "name": "offset",
            "in": "query",
            "required": false,
            "schema": {
              "type": "integer",
              "minimum": 0,
              "default": 0,
              "title": "Offset"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": {
                    "$ref": "#/components/schemas/RemitResponse"
                  },
                  "title": "Response List Remits Remit Get"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/remit/active/{bmu_id}": {
      "get": {
        "tags": [
          "REMIT"
        ],
        "summary": "Active Remits",
        "operationId": "active_remits_remit_active__bmu_id__get",
        "parameters": [
          {
            "name": "bmu_id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string",
              "title": "Bmu Id"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": {
                    "$ref": "#/components/schemas/RemitResponse"
                  },
                  "title": "Response Active Remits Remit Active  Bmu Id  Get"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/remit/{remit_id}": {
      "get": {
        "tags": [
          "REMIT"
        ],
        "summary": "Get Remit",
        "operationId": "get_remit_remit__remit_id__get",
        "parameters": [
          {
            "name": "remit_id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "integer",
              "title": "Remit Id"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/RemitResponse"
                }
              }
            }
          },
          "422": {
            "description": "Validation Error",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/HTTPValidationError"
                }
              }
            }
          }
        }
      }
    },
    "/remit/refresh": {
      "post": {
        "tags": [
          "REMIT"
        ],
        "summary": "Force Refresh Remit",
        "description": "Force an immediate re-fetch of all active REMIT records from Elexon API.\n\nUseful after an incident, or to force an update without waiting for HH:00.\nReturns the number of persisted records.",
        "operationId": "force_refresh_remit_remit_refresh_post",
        "responses": {
          "200": {
            "description": "Successful Response",
            "content": {
              "application/json": {
                "schema": {

                }
              }
            }
          }
        }
      }
    },
    "/visual/pn": {
      "get": {
        "tags": [
          "Visualisation"
        ],
        "summary": "Visualise Sofia PN generation (full + 48h zoom)",
        "description": "Returns an HTML report with 2 matplotlib charts for aggregated generation of the 4 Sofia BMUs (T_SOFOW-11/12/21/22): full period and recent zoom.",
        "operationId": "visualise_pn_generation_visual_pn_get",
        "parameters": [
          {
            "name": "from_date",
            "in": "query",
            "required": false,
            "schema": {
              "type": "string",
              "format": "date-time",
              "description": "Period start (UTC). Default: 2026-04-01T00:00:00Z.",
              "default": "2026-04-01T00:00:00Z",
              "title": "From Date"
            },
            "description": "Period start (UTC). Default: 2026-04-01T00:00:00Z."
          },
          {
            "name": "to_date",
            "in": "query",
            "required": false,
            "schema": {
              "anyOf": [
                {
                  "type": "string",
                  "format": "date-time"
                },
                {
                  "type": "null"
                }
              ],
              "description": "Period end (UTC). Default: latest available data.",
              "title": "To Date"
            },
            "description": "Period end (UTC). Default: latest available data."
          },
          {
            "name": "zoom_hours",
            "in": "query",
            "required": false,
            "schema": {
              "type": "integer",
              "maximum": 168,
              "minimum": 1,
              "description": "Zoom window (hours) at end of series. Default: 48.",
              "default": 48,
              "title": "Zoom Hours"
            },
            "description": "Zoom window (hours) at end of series. Default: 48."
          }
        ],
        "responses": {
          "200": {
            "description": "HTML report with base64-encoded charts.",
            "content": {
              "text/html": {
                "schema": {
                  "type": "string"
                }
              }
            }
          },
          "400": {
            "description": "Invalid request (from_date \u003E to_date)."
          },
          "404": {
            "description": "No generation data available for requested period."
          },
          "422": {
            "description": "Validation error (e.g. invalid zoom_hours) or requested to_date is too recent (beyond latest available data)."
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "HTTPValidationError": {
        "properties": {
          "detail": {
            "items": {
              "$ref": "#/components/schemas/ValidationError"
            },
            "type": "array",
            "title": "Detail"
          }
        },
        "type": "object",
        "title": "HTTPValidationError"
      },
      "PnDateRange": {
        "properties": {
          "oldest": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Oldest"
          },
          "latest": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Latest"
          }
        },
        "type": "object",
        "required": [
          "oldest",
          "latest"
        ],
        "title": "PnDateRange"
      },
      "PnLatestSettlementPeriod": {
        "properties": {
          "bmu_id": {
            "type": "string",
            "title": "Bmu Id"
          },
          "settlement_period": {
            "anyOf": [
              {
                "type": "integer"
              },
              {
                "type": "null"
              }
            ],
            "title": "Settlement Period"
          },
          "time_from": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Time From"
          }
        },
        "type": "object",
        "required": [
          "bmu_id",
          "settlement_period",
          "time_from"
        ],
        "title": "PnLatestSettlementPeriod"
      },
      "PnResponse": {
        "properties": {
          "bmu_id": {
            "type": "string",
            "title": "Bmu Id"
          },
          "time_from": {
            "type": "string",
            "format": "date-time",
            "title": "Time From"
          },
          "time_to": {
            "type": "string",
            "format": "date-time",
            "title": "Time To"
          },
          "settlement_period": {
            "type": "integer",
            "title": "Settlement Period"
          },
          "level_mw": {
            "type": "number",
            "title": "Level Mw"
          },
          "source": {
            "type": "string",
            "title": "Source",
            "default": "pn"
          }
        },
        "type": "object",
        "required": [
          "bmu_id",
          "time_from",
          "time_to",
          "settlement_period",
          "level_mw"
        ],
        "title": "PnResponse",
        "description": "Réponse API."
      },
      "RemitResponse": {
        "properties": {
          "id": {
            "type": "integer",
            "title": "Id"
          },
          "mrid": {
            "type": "string",
            "title": "Mrid"
          },
          "revision_number": {
            "type": "integer",
            "title": "Revision Number"
          },
          "bmu_id": {
            "type": "string",
            "title": "Bmu Id"
          },
          "participant_id": {
            "type": "string",
            "title": "Participant Id"
          },
          "asset_id": {
            "type": "string",
            "title": "Asset Id"
          },
          "unavailability_type": {
            "type": "string",
            "title": "Unavailability Type"
          },
          "event_type": {
            "type": "string",
            "title": "Event Type"
          },
          "message_heading": {
            "type": "string",
            "title": "Message Heading"
          },
          "fuel_type": {
            "type": "string",
            "title": "Fuel Type"
          },
          "normal_capacity_mw": {
            "anyOf": [
              {
                "type": "number"
              },
              {
                "type": "null"
              }
            ],
            "title": "Normal Capacity Mw"
          },
          "available_capacity_mw": {
            "anyOf": [
              {
                "type": "number"
              },
              {
                "type": "null"
              }
            ],
            "title": "Available Capacity Mw"
          },
          "unavailable_capacity_mw": {
            "anyOf": [
              {
                "type": "number"
              },
              {
                "type": "null"
              }
            ],
            "title": "Unavailable Capacity Mw"
          },
          "event_status": {
            "type": "string",
            "title": "Event Status"
          },
          "event_start_time": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Event Start Time"
          },
          "event_end_time": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Event End Time"
          },
          "cause": {
            "type": "string",
            "title": "Cause"
          },
          "related_information": {
            "type": "string",
            "title": "Related Information"
          },
          "publish_time": {
            "anyOf": [
              {
                "type": "string",
                "format": "date-time"
              },
              {
                "type": "null"
              }
            ],
            "title": "Publish Time"
          },
          "outage_profile": {
            "type": "string",
            "title": "Outage Profile"
          }
        },
        "type": "object",
        "required": [
          "id",
          "mrid",
          "revision_number",
          "bmu_id",
          "participant_id",
          "asset_id",
          "unavailability_type",
          "event_type",
          "message_heading",
          "fuel_type",
          "normal_capacity_mw",
          "available_capacity_mw",
          "unavailable_capacity_mw",
          "event_status",
          "event_start_time",
          "event_end_time",
          "cause",
          "related_information",
          "publish_time",
          "outage_profile"
        ],
        "title": "RemitResponse",
        "description": "Réponse API — raw_json exclu pour alléger."
      },
      "ValidationError": {
        "properties": {
          "loc": {
            "items": {
              "anyOf": [
                {
                  "type": "string"
                },
                {
                  "type": "integer"
                }
              ]
            },
            "type": "array",
            "title": "Location"
          },
          "msg": {
            "type": "string",
            "title": "Message"
          },
          "type": {
            "type": "string",
            "title": "Error Type"
          },
          "input": {
            "title": "Input"
          },
          "ctx": {
            "type": "object",
            "title": "Context"
          }
        },
        "type": "object",
        "required": [
          "loc",
          "msg",
          "type"
        ],
        "title": "ValidationError"
      }
    }
  }
}