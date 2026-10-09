--
-- PostgreSQL database dump
--

\restrict dwwvw6Vi5TPjAy8phism18fVqF5nw2OLmnZ2L92Yxc6512zb4iR4LfD1aB7XsL7

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dispatch_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.dispatch_status_enum AS ENUM (
    'pending',
    'on_time',
    'delayed'
);


--
-- Name: pdi_result_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pdi_result_enum AS ENUM (
    'pass',
    'fail'
);


--
-- Name: pdi_stage_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pdi_stage_enum AS ENUM (
    'in_process',
    'final'
);


--
-- Name: ppe_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ppe_role_enum AS ENUM (
    'planning',
    'operator',
    'qa',
    'dispatch',
    'admin'
);


--
-- Name: schedule_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.schedule_status_enum AS ENUM (
    'pending',
    'planned',
    'issued'
);


--
-- Name: stock_movement_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.stock_movement_type AS ENUM (
    'in',
    'out'
);


--
-- Name: fn_trg_dispatch_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_trg_dispatch_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.actual_dispatch_date IS NULL THEN
        NEW.status := 'pending';
    ELSIF NEW.actual_dispatch_date <= NEW.schedule_date THEN
        NEW.status := 'on_time';
    ELSE
        NEW.status := 'delayed';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: fn_trg_oee_calc(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_trg_oee_calc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_qty NUMERIC(12,2) := COALESCE(NEW.ok_qty,0) + COALESCE(NEW.rejected_qty,0);
    v_run_time_sec NUMERIC(10,2) := COALESCE(NEW.run_time_min,0) * 60;
BEGIN
    NEW.availability := CASE WHEN COALESCE(NEW.total_time_min,0) > 0
        THEN ROUND(NEW.run_time_min / NEW.total_time_min, 5) ELSE NULL END;
    NEW.performance := CASE WHEN v_run_time_sec > 0
        THEN ROUND((NEW.standard_cycle_time_sec * v_total_qty) / v_run_time_sec, 5) ELSE NULL END;
    NEW.quality := CASE WHEN v_total_qty > 0
        THEN ROUND(NEW.ok_qty / v_total_qty, 5) ELSE NULL END;
    RETURN NEW;
END;
$$;


--
-- Name: fn_trg_pdi_to_fg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_trg_pdi_to_fg() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_qty NUMERIC(12,2);
BEGIN
    IF NEW.stage = 'final' AND NEW.result = 'pass' THEN
        SELECT total_produced_last_op INTO v_qty
        FROM v_route_card_last_operation
        WHERE route_card_id = NEW.route_card_id;

        IF FOUND THEN
            INSERT INTO finished_goods (route_card_id, fg_qty)
            VALUES (NEW.route_card_id, COALESCE(v_qty, 0));
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: fn_trg_stock_movement(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_trg_stock_movement() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_delta NUMERIC(12,2) := CASE WHEN NEW.movement_type = 'in' THEN NEW.qty ELSE -NEW.qty END;
BEGIN
    INSERT INTO stock_items (material_name, current_qty)
    VALUES (NEW.material_name, v_delta)
    ON CONFLICT (material_name) DO UPDATE
        SET current_qty = stock_items.current_qty + v_delta,
            updated_at = NOW();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bom_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bom_items (
    id integer NOT NULL,
    part_number character varying(80) NOT NULL,
    item_name character varying(100) NOT NULL,
    spec character varying(150),
    item_seq integer DEFAULT 1 NOT NULL,
    rm character varying(100),
    grade character varying(100),
    rm_size character varying(150)
);


--
-- Name: bom_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bom_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bom_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bom_items_id_seq OWNED BY public.bom_items.id;


--
-- Name: bom_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bom_operations (
    id integer NOT NULL,
    bom_item_id integer NOT NULL,
    operation_seq integer NOT NULL,
    operation_name character varying(100) NOT NULL,
    cycle_time_sec numeric(10,2),
    machine_no character varying(80)
);


--
-- Name: bom_operations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bom_operations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bom_operations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bom_operations_id_seq OWNED BY public.bom_operations.id;


--
-- Name: customer_schedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_schedule (
    id integer NOT NULL,
    customer character varying(120) NOT NULL,
    part_number character varying(80) NOT NULL,
    qty numeric(12,2) NOT NULL,
    required_date date NOT NULL,
    status public.schedule_status_enum DEFAULT 'pending'::public.schedule_status_enum,
    created_by integer,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT customer_schedule_qty_check CHECK ((qty > (0)::numeric))
);


--
-- Name: customer_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_schedule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_schedule_id_seq OWNED BY public.customer_schedule.id;


--
-- Name: dispatch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch (
    id integer NOT NULL,
    route_card_id integer NOT NULL,
    order_no character varying(50),
    schedule_date date,
    actual_dispatch_date date,
    qty_dispatched numeric(12,2),
    delay_days integer GENERATED ALWAYS AS (
CASE
    WHEN ((actual_dispatch_date IS NOT NULL) AND (schedule_date IS NOT NULL)) THEN (actual_dispatch_date - schedule_date)
    ELSE NULL::integer
END) STORED,
    status public.dispatch_status_enum DEFAULT 'pending'::public.dispatch_status_enum,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT dispatch_qty_dispatched_check CHECK ((qty_dispatched >= (0)::numeric))
);


--
-- Name: dispatch_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dispatch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dispatch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dispatch_id_seq OWNED BY public.dispatch.id;


--
-- Name: down_time_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.down_time_reasons (
    id integer NOT NULL,
    reason character varying(150) NOT NULL
);


--
-- Name: down_time_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.down_time_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: down_time_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.down_time_reasons_id_seq OWNED BY public.down_time_reasons.id;


--
-- Name: finished_goods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.finished_goods (
    id integer NOT NULL,
    route_card_id integer NOT NULL,
    fg_qty numeric(12,2) NOT NULL,
    fg_date date DEFAULT CURRENT_DATE,
    warehouse character varying(50),
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT finished_goods_fg_qty_check CHECK ((fg_qty >= (0)::numeric))
);


--
-- Name: finished_goods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finished_goods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finished_goods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finished_goods_id_seq OWNED BY public.finished_goods.id;


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machines (
    machine_no character varying(30) NOT NULL,
    machine_name character varying(100),
    department character varying(80),
    is_active boolean DEFAULT true
);


--
-- Name: part_routing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.part_routing (
    id integer NOT NULL,
    part_number character varying(80) NOT NULL,
    operation_name character varying(100) NOT NULL,
    operation_seq integer NOT NULL,
    cycle_time_sec numeric(10,2),
    machine_no character varying(80)
);


--
-- Name: COLUMN part_routing.cycle_time_sec; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.part_routing.cycle_time_sec IS 'Standard cycle time in seconds, from the department cycle-time sheet. This is the reference value; production_oee_entries.standard_cycle_time_sec remains a per-entry field but should match this for the same part+operation.';


--
-- Name: COLUMN part_routing.machine_no; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.part_routing.machine_no IS 'Machine code(s) this operation normally runs on, from the cycle-time sheet (free text -- may list more than one interchangeable machine, e.g. "DM-01,02,03").';


--
-- Name: part_routing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.part_routing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: part_routing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.part_routing_id_seq OWNED BY public.part_routing.id;


--
-- Name: parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parts (
    part_number character varying(80) NOT NULL,
    part_name character varying(150),
    customer_name character varying(200)
);


--
-- Name: pdi_checks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pdi_checks (
    id integer NOT NULL,
    route_card_id integer NOT NULL,
    stage public.pdi_stage_enum NOT NULL,
    inspector_id integer,
    result public.pdi_result_enum NOT NULL,
    remarks text,
    checked_at timestamp without time zone DEFAULT now()
);


--
-- Name: pdi_checks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pdi_checks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pdi_checks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pdi_checks_id_seq OWNED BY public.pdi_checks.id;


--
-- Name: ppe_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ppe_users (
    id integer NOT NULL,
    username character varying(80) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(150),
    role public.ppe_role_enum NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: ppe_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ppe_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ppe_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ppe_users_id_seq OWNED BY public.ppe_users.id;


--
-- Name: production_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_entries (
    id integer NOT NULL,
    route_card_id integer NOT NULL,
    operation_name character varying(100) NOT NULL,
    operation_seq integer NOT NULL,
    entry_date date DEFAULT CURRENT_DATE,
    shift character varying(10),
    operator_name character varying(150),
    machine_no character varying(30),
    qty_planned numeric(12,2) DEFAULT 0 NOT NULL,
    qty_produced numeric(12,2) DEFAULT 0 NOT NULL,
    ok_qty numeric(12,2) DEFAULT 0 NOT NULL,
    rejected_qty numeric(12,2) DEFAULT 0 NOT NULL,
    rework_qty numeric(12,2) DEFAULT 0 NOT NULL,
    hold_qty numeric(12,2) DEFAULT 0 NOT NULL,
    balance_qty numeric(12,2) GENERATED ALWAYS AS ((qty_planned - qty_produced)) STORED,
    down_time_min numeric(10,2) DEFAULT 0,
    down_time_reason character varying(150),
    remarks text,
    entry_by integer,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: production_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.production_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.production_entries_id_seq OWNED BY public.production_entries.id;


--
-- Name: production_log_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_log_entries (
    id integer NOT NULL,
    line character varying(30) NOT NULL,
    part_number character varying(80) NOT NULL,
    entry_date date NOT NULL,
    machine_no character varying(30),
    operation_name character varying(100) NOT NULL,
    operator_name character varying(150),
    start_time time without time zone,
    end_time time without time zone,
    planned_qty numeric(12,2),
    produced_qty numeric(12,2),
    ok_qty numeric(12,2),
    ng_qty numeric(12,2),
    rejection_reason character varying(150),
    entry_by integer,
    created_at timestamp without time zone DEFAULT now(),
    machine_name character varying(100),
    standard_cycle_time_sec numeric(10,2),
    extra_down_time_min numeric(10,2),
    down_time_reason character varying(150),
    total_time_min numeric(10,2),
    planned_down_time_min numeric(10,2),
    down_time_min numeric(10,2),
    run_time_min numeric(10,2),
    availability numeric(6,5),
    performance numeric(6,5),
    quality numeric(6,5),
    oee numeric(6,5),
    shift character varying(10),
    bom_item_name character varying(100)
);


--
-- Name: production_log_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.production_log_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_log_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.production_log_entries_id_seq OWNED BY public.production_log_entries.id;


--
-- Name: production_oee_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_oee_entries (
    id integer NOT NULL,
    sr_no integer,
    entry_date date NOT NULL,
    shift character varying(10),
    operator_name character varying(150),
    machine_no character varying(30),
    operation_name character varying(100),
    part_name character varying(100),
    standard_cycle_time_sec numeric(10,2),
    ok_qty numeric(12,2) DEFAULT 0,
    rejected_qty numeric(12,2) DEFAULT 0,
    rejection_reason character varying(150),
    total_qty_produced numeric(12,2) GENERATED ALWAYS AS ((COALESCE(ok_qty, (0)::numeric) + COALESCE(rejected_qty, (0)::numeric))) STORED,
    total_time_min numeric(10,2),
    run_time_min numeric(10,2),
    run_time_sec numeric(10,2) GENERATED ALWAYS AS ((COALESCE(run_time_min, (0)::numeric) * (60)::numeric)) STORED,
    down_time_min numeric(10,2) DEFAULT 0,
    down_time_reason character varying(150),
    availability numeric(6,5),
    performance numeric(6,5),
    quality numeric(6,5),
    oee numeric(6,5) GENERATED ALWAYS AS (((COALESCE(availability, (0)::numeric) * COALESCE(performance, (0)::numeric)) * COALESCE(quality, (0)::numeric))) STORED,
    entry_by integer,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: production_oee_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.production_oee_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_oee_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.production_oee_entries_id_seq OWNED BY public.production_oee_entries.id;


--
-- Name: rejection_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rejection_reasons (
    id integer NOT NULL,
    reason character varying(150) NOT NULL,
    category character varying(50)
);


--
-- Name: rejection_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rejection_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rejection_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rejection_reasons_id_seq OWNED BY public.rejection_reasons.id;


--
-- Name: route_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route_cards (
    id integer NOT NULL,
    job_card_no character varying(50) NOT NULL,
    part_number character varying(80) NOT NULL,
    material_name character varying(120),
    issued_qty numeric(12,2) NOT NULL,
    department character varying(80),
    customer character varying(120),
    entered_by integer,
    entered_at timestamp without time zone DEFAULT now(),
    CONSTRAINT route_cards_issued_qty_check CHECK ((issued_qty >= (0)::numeric))
);


--
-- Name: route_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.route_cards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: route_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.route_cards_id_seq OWNED BY public.route_cards.id;


--
-- Name: stock_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_items (
    id integer NOT NULL,
    material_name character varying(120) NOT NULL,
    current_qty numeric(12,2) DEFAULT 0 NOT NULL,
    reorder_level numeric(12,2) DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: stock_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_items_id_seq OWNED BY public.stock_items.id;


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_movements (
    id integer NOT NULL,
    material_name character varying(120) NOT NULL,
    movement_type public.stock_movement_type NOT NULL,
    qty numeric(12,2) NOT NULL,
    reason character varying(150),
    entry_by integer,
    entry_date date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT stock_movements_qty_check CHECK ((qty > (0)::numeric))
);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_movements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_movements_id_seq OWNED BY public.stock_movements.id;


--
-- Name: v_operation_progress; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_operation_progress AS
 SELECT route_card_id,
    operation_seq,
    operation_name,
    sum(qty_produced) AS total_produced,
    sum(ok_qty) AS total_ok,
    sum(rejected_qty) AS total_rejected,
    sum(rework_qty) AS total_rework,
    sum(hold_qty) AS total_hold
   FROM public.production_entries
  GROUP BY route_card_id, operation_seq, operation_name;


--
-- Name: v_route_card_last_operation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_route_card_last_operation AS
 SELECT DISTINCT ON (route_card_id) route_card_id,
    operation_seq,
    operation_name,
    sum(qty_produced) OVER (PARTITION BY route_card_id, operation_seq) AS total_produced_last_op
   FROM public.production_entries
  ORDER BY route_card_id, operation_seq DESC, entry_date DESC;


--
-- Name: v_stock_shortage; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stock_shortage AS
 SELECT material_name,
    current_qty,
    reorder_level,
    (reorder_level - current_qty) AS short_by
   FROM public.stock_items
  WHERE (current_qty < reorder_level);


--
-- Name: bom_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_items ALTER COLUMN id SET DEFAULT nextval('public.bom_items_id_seq'::regclass);


--
-- Name: bom_operations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_operations ALTER COLUMN id SET DEFAULT nextval('public.bom_operations_id_seq'::regclass);


--
-- Name: customer_schedule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_schedule ALTER COLUMN id SET DEFAULT nextval('public.customer_schedule_id_seq'::regclass);


--
-- Name: dispatch id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch ALTER COLUMN id SET DEFAULT nextval('public.dispatch_id_seq'::regclass);


--
-- Name: down_time_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.down_time_reasons ALTER COLUMN id SET DEFAULT nextval('public.down_time_reasons_id_seq'::regclass);


--
-- Name: finished_goods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods ALTER COLUMN id SET DEFAULT nextval('public.finished_goods_id_seq'::regclass);


--
-- Name: part_routing id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.part_routing ALTER COLUMN id SET DEFAULT nextval('public.part_routing_id_seq'::regclass);


--
-- Name: pdi_checks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pdi_checks ALTER COLUMN id SET DEFAULT nextval('public.pdi_checks_id_seq'::regclass);


--
-- Name: ppe_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppe_users ALTER COLUMN id SET DEFAULT nextval('public.ppe_users_id_seq'::regclass);


--
-- Name: production_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_entries ALTER COLUMN id SET DEFAULT nextval('public.production_entries_id_seq'::regclass);


--
-- Name: production_log_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_log_entries ALTER COLUMN id SET DEFAULT nextval('public.production_log_entries_id_seq'::regclass);


--
-- Name: production_oee_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_oee_entries ALTER COLUMN id SET DEFAULT nextval('public.production_oee_entries_id_seq'::regclass);


--
-- Name: rejection_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejection_reasons ALTER COLUMN id SET DEFAULT nextval('public.rejection_reasons_id_seq'::regclass);


--
-- Name: route_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_cards ALTER COLUMN id SET DEFAULT nextval('public.route_cards_id_seq'::regclass);


--
-- Name: stock_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_items ALTER COLUMN id SET DEFAULT nextval('public.stock_items_id_seq'::regclass);


--
-- Name: stock_movements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements ALTER COLUMN id SET DEFAULT nextval('public.stock_movements_id_seq'::regclass);


--
-- Name: bom_items bom_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_items
    ADD CONSTRAINT bom_items_pkey PRIMARY KEY (id);


--
-- Name: bom_operations bom_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_operations
    ADD CONSTRAINT bom_operations_pkey PRIMARY KEY (id);


--
-- Name: customer_schedule customer_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_schedule
    ADD CONSTRAINT customer_schedule_pkey PRIMARY KEY (id);


--
-- Name: dispatch dispatch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch
    ADD CONSTRAINT dispatch_pkey PRIMARY KEY (id);


--
-- Name: down_time_reasons down_time_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.down_time_reasons
    ADD CONSTRAINT down_time_reasons_pkey PRIMARY KEY (id);


--
-- Name: down_time_reasons down_time_reasons_reason_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.down_time_reasons
    ADD CONSTRAINT down_time_reasons_reason_key UNIQUE (reason);


--
-- Name: finished_goods finished_goods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_pkey PRIMARY KEY (id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (machine_no);


--
-- Name: part_routing part_routing_part_number_operation_seq_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.part_routing
    ADD CONSTRAINT part_routing_part_number_operation_seq_key UNIQUE (part_number, operation_seq);


--
-- Name: part_routing part_routing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.part_routing
    ADD CONSTRAINT part_routing_pkey PRIMARY KEY (id);


--
-- Name: parts parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parts
    ADD CONSTRAINT parts_pkey PRIMARY KEY (part_number);


--
-- Name: pdi_checks pdi_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pdi_checks
    ADD CONSTRAINT pdi_checks_pkey PRIMARY KEY (id);


--
-- Name: pdi_checks pdi_checks_route_card_id_stage_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pdi_checks
    ADD CONSTRAINT pdi_checks_route_card_id_stage_key UNIQUE (route_card_id, stage);


--
-- Name: ppe_users ppe_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppe_users
    ADD CONSTRAINT ppe_users_pkey PRIMARY KEY (id);


--
-- Name: ppe_users ppe_users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ppe_users
    ADD CONSTRAINT ppe_users_username_key UNIQUE (username);


--
-- Name: production_entries production_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_entries
    ADD CONSTRAINT production_entries_pkey PRIMARY KEY (id);


--
-- Name: production_log_entries production_log_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_log_entries
    ADD CONSTRAINT production_log_entries_pkey PRIMARY KEY (id);


--
-- Name: production_oee_entries production_oee_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_oee_entries
    ADD CONSTRAINT production_oee_entries_pkey PRIMARY KEY (id);


--
-- Name: rejection_reasons rejection_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejection_reasons
    ADD CONSTRAINT rejection_reasons_pkey PRIMARY KEY (id);


--
-- Name: rejection_reasons rejection_reasons_reason_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rejection_reasons
    ADD CONSTRAINT rejection_reasons_reason_key UNIQUE (reason);


--
-- Name: route_cards route_cards_job_card_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_cards
    ADD CONSTRAINT route_cards_job_card_no_key UNIQUE (job_card_no);


--
-- Name: route_cards route_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_cards
    ADD CONSTRAINT route_cards_pkey PRIMARY KEY (id);


--
-- Name: stock_items stock_items_material_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_items
    ADD CONSTRAINT stock_items_material_name_key UNIQUE (material_name);


--
-- Name: stock_items stock_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_items
    ADD CONSTRAINT stock_items_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: bom_items uq_bom_part_item; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_items
    ADD CONSTRAINT uq_bom_part_item UNIQUE (part_number, item_name);


--
-- Name: bom_operations uq_bomop_item_seq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_operations
    ADD CONSTRAINT uq_bomop_item_seq UNIQUE (bom_item_id, operation_seq);


--
-- Name: idx_bom_items_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bom_items_part ON public.bom_items USING btree (part_number);


--
-- Name: idx_customer_schedule_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_schedule_date ON public.customer_schedule USING btree (required_date);


--
-- Name: idx_customer_schedule_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_schedule_status ON public.customer_schedule USING btree (status);


--
-- Name: idx_dispatch_route_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispatch_route_card ON public.dispatch USING btree (route_card_id);


--
-- Name: idx_dispatch_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispatch_status ON public.dispatch USING btree (status);


--
-- Name: idx_fg_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fg_date ON public.finished_goods USING btree (fg_date);


--
-- Name: idx_fg_route_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fg_route_card ON public.finished_goods USING btree (route_card_id);


--
-- Name: idx_oee_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oee_date ON public.production_oee_entries USING btree (entry_date);


--
-- Name: idx_oee_machine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oee_machine ON public.production_oee_entries USING btree (machine_no);


--
-- Name: idx_oee_operation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oee_operation ON public.production_oee_entries USING btree (operation_name);


--
-- Name: idx_part_routing_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_part_routing_part ON public.part_routing USING btree (part_number);


--
-- Name: idx_pdi_route_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pdi_route_card ON public.pdi_checks USING btree (route_card_id);


--
-- Name: idx_pdi_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pdi_stage ON public.pdi_checks USING btree (stage);


--
-- Name: idx_prod_entries_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_entries_date ON public.production_entries USING btree (entry_date);


--
-- Name: idx_prod_entries_route_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_entries_route_card ON public.production_entries USING btree (route_card_id);


--
-- Name: idx_prod_entries_seq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prod_entries_seq ON public.production_entries USING btree (route_card_id, operation_seq);


--
-- Name: idx_production_log_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_log_date ON public.production_log_entries USING btree (entry_date);


--
-- Name: idx_production_log_line; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_log_line ON public.production_log_entries USING btree (line);


--
-- Name: idx_production_log_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_log_part ON public.production_log_entries USING btree (part_number);


--
-- Name: idx_route_cards_job_card_no; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_route_cards_job_card_no ON public.route_cards USING btree (job_card_no);


--
-- Name: idx_route_cards_part; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_route_cards_part ON public.route_cards USING btree (part_number);


--
-- Name: idx_stock_items_material; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_items_material ON public.stock_items USING btree (material_name);


--
-- Name: idx_stock_movements_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_date ON public.stock_movements USING btree (entry_date);


--
-- Name: idx_stock_movements_material; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_material ON public.stock_movements USING btree (material_name);


--
-- Name: dispatch trg_dispatch_status; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_dispatch_status BEFORE INSERT OR UPDATE ON public.dispatch FOR EACH ROW EXECUTE FUNCTION public.fn_trg_dispatch_status();


--
-- Name: production_oee_entries trg_oee_calc; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_oee_calc BEFORE INSERT OR UPDATE ON public.production_oee_entries FOR EACH ROW EXECUTE FUNCTION public.fn_trg_oee_calc();


--
-- Name: pdi_checks trg_pdi_to_fg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pdi_to_fg AFTER INSERT ON public.pdi_checks FOR EACH ROW EXECUTE FUNCTION public.fn_trg_pdi_to_fg();


--
-- Name: stock_movements trg_stock_movement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stock_movement AFTER INSERT ON public.stock_movements FOR EACH ROW EXECUTE FUNCTION public.fn_trg_stock_movement();


--
-- Name: bom_operations bom_operations_bom_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bom_operations
    ADD CONSTRAINT bom_operations_bom_item_id_fkey FOREIGN KEY (bom_item_id) REFERENCES public.bom_items(id) ON DELETE CASCADE;


--
-- Name: customer_schedule customer_schedule_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_schedule
    ADD CONSTRAINT customer_schedule_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.ppe_users(id);


--
-- Name: dispatch dispatch_route_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch
    ADD CONSTRAINT dispatch_route_card_id_fkey FOREIGN KEY (route_card_id) REFERENCES public.route_cards(id);


--
-- Name: finished_goods finished_goods_route_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_route_card_id_fkey FOREIGN KEY (route_card_id) REFERENCES public.route_cards(id);


--
-- Name: pdi_checks pdi_checks_inspector_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pdi_checks
    ADD CONSTRAINT pdi_checks_inspector_id_fkey FOREIGN KEY (inspector_id) REFERENCES public.ppe_users(id);


--
-- Name: pdi_checks pdi_checks_route_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pdi_checks
    ADD CONSTRAINT pdi_checks_route_card_id_fkey FOREIGN KEY (route_card_id) REFERENCES public.route_cards(id);


--
-- Name: production_entries production_entries_entry_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_entries
    ADD CONSTRAINT production_entries_entry_by_fkey FOREIGN KEY (entry_by) REFERENCES public.ppe_users(id);


--
-- Name: production_entries production_entries_route_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_entries
    ADD CONSTRAINT production_entries_route_card_id_fkey FOREIGN KEY (route_card_id) REFERENCES public.route_cards(id);


--
-- Name: production_log_entries production_log_entries_entry_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_log_entries
    ADD CONSTRAINT production_log_entries_entry_by_fkey FOREIGN KEY (entry_by) REFERENCES public.ppe_users(id);


--
-- Name: production_oee_entries production_oee_entries_entry_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_oee_entries
    ADD CONSTRAINT production_oee_entries_entry_by_fkey FOREIGN KEY (entry_by) REFERENCES public.ppe_users(id);


--
-- Name: route_cards route_cards_entered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route_cards
    ADD CONSTRAINT route_cards_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES public.ppe_users(id);


--
-- Name: stock_movements stock_movements_entry_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_entry_by_fkey FOREIGN KEY (entry_by) REFERENCES public.ppe_users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict dwwvw6Vi5TPjAy8phism18fVqF5nw2OLmnZ2L92Yxc6512zb4iR4LfD1aB7XsL7

