import Data.List (isInfixOf)

extract :: String -> String -> String
extract marker line =
  case dropWhile (/= head marker) <$> safeTail (breakOn marker line) of
    Just rest ->
      let value = drop (length marker) rest
       in takeWhile (/= '"') value
    Nothing -> ""
  where
    breakOn needle haystack =
      case spanList needle haystack of
        Just (_, suffix) -> suffix
        Nothing -> ""
    safeTail (_, []) = Nothing
    safeTail (_, xs) = Just xs
    spanList needle haystack =
      go "" haystack
      where
        go _ [] = Nothing
        go prefix rest
          | needle `isPrefixOf` rest = Just (prefix, rest)
          | otherwise = go (prefix ++ [head rest]) (tail rest)
    isPrefixOf [] _ = True
    isPrefixOf _ [] = False
    isPrefixOf (a:as) (b:bs) = a == b && isPrefixOf as bs

main :: IO ()
main = loop
  where
    loop = do
      eof <- getContents
      mapM_ handleLine (lines eof)
    handleLine line
      | "\"type\":\"HELLO\"" `isInfixOf` line =
          putStrLn "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"haskell-length-01\",\"language\":\"haskell\",\"runtimeVersion\":\"ghc\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.length-hs\"}]}"
      | "\"type\":\"JOB_START\"" `isInfixOf` line =
          if "\"capability\":\"text.length-hs\"" `isInfixOf` line
            then do
              let jobId = extract "\"jobId\":\"" line
              let text = extract "\"text\":\"" line
              putStrLn ("{\"type\":\"JOB_RESULT\",\"jobId\":\"" ++ jobId ++ "\",\"output\":{\"length\":" ++ show (length text) ++ "}}")
            else putStrLn "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}"
      | otherwise = pure ()
