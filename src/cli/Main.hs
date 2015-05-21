module Main where

import Control.Monad
import Data.List
import System.Console.GetOpt
import System.Environment
import System.Exit
import System.IO
import System.Random

import Data.Elocrypt

version = "elocrypt 0.4.0"
termLen = 80

main :: IO ()
main = do
  args <- getArgs
  opts <- elocryptOpts args
  gen  <- getStdGen

  when (optHelp opts) $ do
    hPutStrLn stderr usage
    exitSuccess
  when (optVersion opts) $ do
    hPutStrLn stderr version
    exitSuccess

  putStrLn (passwords opts gen)

passwords :: RandomGen g => Options -> g -> String
passwords opts gen = concat . intersperse "\n" . map (concat . intersperse "  ") . group' groupSize $ ps
  where ps = take (optNumber opts) . newPasswords (optLength opts) $ gen
        groupSize = termLen `div` (optLength opts + 2)

group' :: Int -> [a] -> [[a]]
group' _ [] = []
group' i ls = g:(group' i ls')
  where (g, ls') = splitAt i ls

data Options
  = Options { optLength  :: Int,    -- Size of the password(s)
              optNumber  :: Int,    -- Number of passwords to generate
              optHelp    :: Bool,
              optVersion :: Bool }
  deriving (Show)

defaultOptions :: Options
defaultOptions = Options { optLength = 8,
                           optNumber = 42,
                           optHelp = False,
                           optVersion = False }

options :: [OptDescr (Options -> Options)]
options = [Option ['n'] ["number"] (ReqArg (\n o -> o {optNumber = read n}) "NUMBER") "The number of passwords to generate (default: 42)",
           Option ['h'] ["help"] (NoArg (\o -> o { optHelp = True })) "Show this help",
           Option ['v'] ["version"] (NoArg (\o -> o { optVersion = True })) "Show version and exit"]

elocryptOpts :: [String] -> IO Options
elocryptOpts args = do
  (opts, nonopts) <- elocryptOpts' args
  return $ if (null nonopts)
     then opts
     else opts { optLength = read (head nonopts) }

elocryptOpts' :: [String] -> IO (Options, [String])
elocryptOpts' args = case getOpt Permute options args of
  (opts, nonopts, [])   -> return (foldl (flip id) defaultOptions opts, nonopts)
  (_   , _      , errs) -> do
    -- TODO: Refactor me
    hPutStrLn stderr (concat errs)
    hPutStrLn stderr usage
    exitFailure

usage :: String
usage = usageInfo header options
  where header = "Usage: elocrypt [option...] length"
