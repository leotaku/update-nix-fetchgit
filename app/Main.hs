{-# LANGUAGE LambdaCase #-}

module Main where

import           Data.Text           (Text, pack)
import           Data.Text.IO        (readFile, writeFile)
import           Prelude             hiding (readFile, writeFile)
import           System.Environment  (getArgs)
import           System.Exit
import           System.IO           (hPutStrLn, stderr)
import           Update.Nix.FetchGit
import           Update.Nix.FetchGit.Utils
import           Update.Nix.FetchGit.Warning
import           Update.Span

main :: IO ()
main =
  -- Super simple command line parsing at the moment, just look for one
  -- filename and optionally pass extra arguments to `nix-prefetch-git`.
  getArgs >>= \case
    [filename] -> processFile filename []
    (filename:args) -> processFile filename (map pack args)
    _ -> do
      putStrLn "Usage: update-nix-fetchgit filename [<extra-prefetch-args>]"
      exitWith (ExitFailure 1)

printErrorAndExit :: Warning -> IO ()
printErrorAndExit e = do
  hPutStrLn stderr (formatWarning e)
  exitWith (ExitFailure 1)

processFile :: FilePath -> [Text] -> IO ()
processFile filename args = do
  t <- readFile filename
  -- Get the updates from this file.
  updatesFromFile filename args >>= \case
    -- If we have any errors, print them and finish.
    Left ws -> printErrorAndExit ws
    Right us ->
      -- Update the text of the file in memory.
      case updateSpans us t of
        -- If updates are needed, write to the file.
        t' | t' /= t -> do
          writeFile filename t'
          putStrLn $ "Made " ++ (show $ length us) ++ " changes"

        _ -> putStrLn "No updates"
