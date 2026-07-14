let text = ($env.OMNIFORGE_TEXT? | default "")
$text | split chars | reverse | str join
