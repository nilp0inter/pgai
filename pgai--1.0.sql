
/*
create table @extschema@.secret
( id int not null generated by default as identity primary key
, name text unique
, secret text not null
, rolname name not null
);
revoke all on @extschema@.secret from public;
grant select on @extschema@.secret to public;
alter table secret enable row level security;
create policy secret_access on @extschema@.secret as permissive for select using (to_regrole(rolname) is not null and pg_has_role(current_user, rolname, 'MEMBER'));
select pg_catalog.pg_extension_config_dump('@extschema@.secret', '');

create function @extschema@.set_secret(_name text, _secret text, _rolname name) returns int
as $func$
insert into @extschema@.secret (name, secret, rolname)
values (_name, _secret, _rolname)
returning id
$func$ language sql strict volatile
;

create function @extschema@.get_secret(_name text) returns text
as $func$
select secret from @extschema@.secret where name = _name
$func$ language sql strict volatile
;

create function @extschema@.tokenize(_model text, _content text) returns int[]
as $func$
import tiktoken
encoding = tiktoken.encoding_for_model(_model)
tokens = encoding.encode(_content)
return tokens
$func$ language plpython3u strict volatile parallel safe
;
*/

create function @extschema@.embed(_model text, _api_key text, _content text) returns vector
as $func$
import openai
client = openai.OpenAI(api_key=_api_key)
response = client.embeddings.create(input = [_content], model=_model)
return response.data[0].embedding
$func$ language plpython3u strict volatile parallel safe security invoker
;


/*
create function @extschema@.embed(_model text, _api_key text, _tokens int[]) returns vector
as $func$
import openai
import json
client = openai.OpenAI(api_key=_api_key)
response = client.embeddings.create(input = [_tokens], model=_model)
return response.data[0].embedding
$func$ language plpython3u strict volatile parallel safe
;
*/