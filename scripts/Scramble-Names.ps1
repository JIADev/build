if (get-table firsts) { en "drop table firsts" }
if (get-table lasts) { en "drop table lasts" }
en "
select distinct
substring(primaryname, 0, charindex(' ', primaryname)) as first
into firsts
from genealogy.account
where primaryname not like '% % %'
" -timeout 500
en "
select distinct
substring(primaryname, charindex(' ', primaryname), len(primaryname)) as last
into lasts
from genealogy.account
where primaryname not like '% % %'
" -timeout 500

er "select Id, PrimaryName from Genealogy.Account" | `
    % { $id = $_.Id;
        $old = $_.primaryname;
        $first = (er "select top 1 first from firsts order by newid()").first.trim()
        $last = (er "select top 1 last from lasts order by newid()").last.trim()
        $sql = "update genealogy.account set primaryname = '$first $last',
                secondaryname = '$last, $first' where Id = $id -- (was: $old)"
        $sql
        en $sql
        }

get-table AccountHistory% | % { $_.TABLE_NAME }  | `
    % {
        $sql = "update h
            set h.PrimaryName = a.PrimaryName,
                h.SecondaryName = a.SecondaryName
            from $_ h join Genealogy.Account a on h.Id = a.Id"
        $sql
        en $sql
        }

get-table Run%Qual | % { $_.TABLE_NAME }  | `
     ? { -not $_.endswith("VolQual")} | `
     % {
        $sql = "update h
            set h.PrimaryName = a.PrimaryName,
                h.SecondaryName = a.SecondaryName
            from $_ h join Genealogy.Account a on h.Id = a.Id"
        $sql
        en $sql
        }

