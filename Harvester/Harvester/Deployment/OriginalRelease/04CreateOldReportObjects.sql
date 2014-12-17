SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CalendarDay](
	[Date] [date] NOT NULL,
 CONSTRAINT [PK_CalendarDay] PRIMARY KEY CLUSTERED
(
	[Date] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddYear](@year int) AS
INSERT CalendarDay
SELECT TOP(100) PERCENT
		CAST([y-m-d] AS DATE) AS [date]
FROM		(
			SELECT		@year AS y,
					m.Number AS m,
					d.Number AS d,
					CAST(@year AS CHAR(4))
					+ '-' + REPLACE(STR(m.Number, 2), ' ', '0')
					+ '-' + REPLACE(STR(d.Number, 2), ' ', '0') AS [y-m-d]

			FROM		master..spt_values AS m
			INNER JOIN	master..spt_values AS d ON d.Type = 'P'
			WHERE		m.Type = 'P'
					AND m.Number BETWEEN 1 AND 12
					AND d.Number BETWEEN 1 AND 31
		) AS d
WHERE		ISDATE([y-m-d]) = 1
ORDER BY	[y-m-d]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[workorder_timeentries] AS
select parent.id AS parent,
	CAST(u.login AS NVARCHAR(MAX)) AS [user],
	CAST(te.spent_on AS DATE) AS date,
	CAST(coalesce((case when (CAST(wov.value AS NVARCHAR(MAX)) = '') then NULL else wov.value end),
				wovp.value) AS NVARCHAR(MAX)) AS workorder,
	CAST(custv.value AS NVARCHAR(MAX)) AS customer,
	CAST(e.name AS NVARCHAR(MAX)) AS activity,
	te.hours AS hours,
	CAST(te.comments AS NVARCHAR(MAX)) AS comments,
	i.id AS issue_id,
	CAST(i.subject AS NVARCHAR(MAX)) AS subject,
	CAST(v.name AS NVARCHAR(MAX)) AS version,
	CAST(p.name AS NVARCHAR(MAX)) AS project,
	te.id AS timeentry_id,
	CAST(ist.name AS NVARCHAR(MAX)) AS status,
	CAST(t.name AS NVARCHAR(MAX)) AS tracker

from Redmine.time_entries te join Redmine.users u
		on te.user_id = u.id
	 join Redmine.enumerations e
		on te.activity_id = e.id
	left join Redmine.projects p
		on te.project_id = p.id
	left join Redmine.issues i
		on te.issue_id = i.id
	left join Redmine.versions v
		on i.fixed_version_id = v.id
	left join Redmine.custom_fields wof
		on wof.type = 'IssueCustomField'
			and wof.name = 'Work Order'
	left join Redmine.custom_fields custf on
		custf.type = 'IssueCustomField'
			and custf.name = 'Customer'
	left join Redmine.custom_values wov
		on wov.customized_type = 'Issue'
		 and wov.customized_id = i.id
		 and wov.custom_field_id = wof.id
	left join Redmine.custom_values custv
		on custv.customized_type = 'Issue'
		 and custv.customized_id = i.id
		 and custv.custom_field_id = custf.id
	join Redmine.issue_statuses ist
		on i.status_id = ist.id
	join Redmine.trackers t
		on i.tracker_id = t.id
	left join Redmine.issue_relations ir
		on ir.issue_from_id = i.id
		 and ir.relation_type = 'blocks'
	left join Redmine.issues parent
		on ir.issue_to_id = parent.id
	left join Redmine.custom_fields wofp
		on wofp.type = 'IssueCustomField'
		 and wofp.name = 'Work Order'
	left join Redmine.custom_values wovp
		on wovp.customized_type = 'Issue'
		 and wovp.customized_id = parent.id
		 and wovp.custom_field_id = wofp.id
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[issue_journals] AS
select jd.id AS id,
	i.id AS issue_id,j.id AS journal_id,
	j.user_id AS user_id,
	j.notes AS notes,
	j.created_on AS created_on,
	jd.property AS property,
	jd.prop_key AS prop_key,
	jd.old_value AS old_value,
	jd.value AS value
from ((Redmine.issues i join Redmine.journals j on(((i.id = j.journalized_id) and (j.journalized_type = 'Issue')))) join Redmine.journal_details jd on((jd.journal_id = j.id)))
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[changes_startdate] AS
select ij.id AS id,
	ij.issue_id AS issue_id,
	ij.journal_id AS journal_id,
	ij.user_id AS user_id,
	ij.notes AS notes,
	ij.created_on AS created_on,
	ij.property AS property,
	ij.prop_key AS prop_key,
	ij.old_value AS old_value,
	ij.value AS value
from issue_journals ij where ij.prop_key = 'start_date'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[changes_estimate] AS
select ij.id AS id,
	ij.issue_id AS issue_id,
	ij.journal_id AS journal_id,
	ij.user_id AS user_id,
	ij.notes AS notes,
	ij.created_on AS created_on,
	ij.property AS property,
	ij.prop_key AS prop_key,
	ij.old_value AS old_value,
	ij.value AS value
from issue_journals ij where ij.prop_key = 'estimated_hours'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[changes_duedate] AS
select ij.id AS id,
	ij.issue_id AS issue_id,
	ij.journal_id AS journal_id,
	ij.user_id AS user_id,
	ij.notes AS notes,
	ij.created_on AS created_on,
	ij.property AS property,
	ij.prop_key AS prop_key,
	ij.old_value AS old_value,
	ij.value AS value
from issue_journals ij where ij.prop_key = 'due_date'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[changes_assignedto] AS
select ij.id AS id,
	ij.issue_id AS issue_id,
	ij.journal_id AS journal_id,
	ij.user_id AS user_id,
	ij.notes AS notes,
	ij.created_on AS created_on,
	ij.property AS property,
	ij.prop_key AS prop_key,
	ij.old_value AS old_value,
	ij.value AS value
from issue_journals ij where (ij.prop_key = 'assigned_to_id')
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[issue_changes_base] AS
select distinct
		cast(ij.created_on as date) AS [date],
		i.id AS id,
		u.[login] AS assigned,
		i.[subject] AS [subject],
		(select cs.old_value AS old_value from changes_startdate cs
			where cs.issue_id = i.id and cs.id =
				(select min(cs2.id) from changes_startdate cs2
					where cs2.issue_id = i.id and cast(cs2.created_on as date) = cast(ij.created_on as date))) AS old_start,
		(select cs.value AS value from changes_startdate cs
			where ((cs.issue_id = i.id) and (cs.id =
				(select max(cs2.id) from changes_startdate cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS new_start,
		(select cs.old_value AS old_value from changes_duedate cs
			where ((cs.issue_id = i.id) and (cs.id =
				(select min(cs2.id) from changes_duedate cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS old_end,
		(select cs.value AS value from changes_duedate cs
			where ((cs.issue_id = i.id) and (cs.id =
				(select max(cs2.id) from changes_duedate cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS new_end,
		(select u.login AS login from (changes_assignedto cs join Redmine.users u on((u.id = cs.old_value)))
			where ((cs.issue_id = i.id) and (cs.id =
				(select min(cs2.id) from changes_assignedto cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS old_assigned,
		(select u.login AS login from (changes_assignedto cs join Redmine.users u on((u.id = cs.value)))
			where ((cs.issue_id = i.id) and (cs.id =
				(select max(cs2.id) from changes_assignedto cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS new_assigned,
		(select cs.old_value AS old_value from changes_estimate cs
			where ((cs.issue_id = i.id) and (cs.id =
				(select min(cs2.id) from changes_estimate cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS old_estimate,
		(select cs.value AS value from changes_estimate cs
			where ((cs.issue_id = i.id) and (cs.id =
				(select max(cs2.id) from changes_estimate cs2
					where ((cs2.issue_id = i.id) and (cast(cs2.created_on as date) = cast(ij.created_on as date))))))) AS new_estimate
	from Redmine.issues i join issue_journals ij
			on i.id = ij.issue_id
		 left join Redmine.users u on i.assigned_to_id = u.id
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[issue_changes] AS
select issue_changes_base.date AS date,
		issue_changes_base.id AS id,
		issue_changes_base.assigned AS assigned,
		issue_changes_base.subject AS subject,
		issue_changes_base.old_start AS old_start,
		issue_changes_base.new_start AS new_start,
		issue_changes_base.old_end AS old_end,
		issue_changes_base.new_end AS new_end,
		issue_changes_base.old_assigned AS old_assigned,
		issue_changes_base.new_assigned AS new_assigned,
		issue_changes_base.old_estimate AS old_estimate,
		issue_changes_base.new_estimate AS new_estimate
from issue_changes_base where
	((issue_changes_base.old_start is not null)
	or (issue_changes_base.new_start is not null)
	or (issue_changes_base.old_end is not null)
	or (issue_changes_base.new_end is not null)
	or (issue_changes_base.old_assigned is not null)
	or (issue_changes_base.new_assigned is not null)
	or (issue_changes_base.old_estimate is not null)
	or (issue_changes_base.new_estimate is not null))
GO
