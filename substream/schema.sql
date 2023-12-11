CREATE TABLE IF NOT EXISTS txs_meta
(
    id     text NOT NULL CONSTRAINT txs_meta_pk PRIMARY KEY,
    hash   text,
    pubkey text,
    "to"   text,
    "from" text,
    r      text,
    s      text,
    v      text
);

create table IF NOT EXISTS  cursors
(
    id         text not null constraint cursor_pk primary key,
    cursor     text,
    block_num  bigint,
    block_id   text
);