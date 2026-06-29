{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set suffix = '_olist_ecomm' -%}

    {%- if custom_schema_name is none -%}
        {%- set base_schema = target.schema | trim -%}
    {%- else -%}
        {%- set base_schema = custom_schema_name | trim -%}
    {%- endif -%}

    {%- if base_schema.endswith(suffix) -%}
        {{ base_schema }}
    {%- else -%}
        {{ base_schema ~ suffix }}
    {%- endif -%}

{%- endmacro %}