{-# LANGUAGE OverloadedStrings #-}

module Main ( main ) where

import           Aura.Packages.Repository
import           Aura.Pacman
import           Aura.Types
import           BasePrelude
import qualified Data.Map.Strict as M
import qualified Data.Text as T
import qualified Data.Text.IO as T
import           Data.Versions
import           Test.Tasty
import           Test.Tasty.HUnit
import           Text.Megaparsec

---

main :: IO ()
main = do
  conf <- T.readFile "test/pacman.conf"
  defaultMain $ suite conf

suite :: T.Text -> TestTree
suite conf = testGroup "Unit Tests"
  [ testGroup "Aura.Core"
    [ testCase "parseDep - python2" $ parseDep "python2" @?= Just (Dep "python2" Anything)
    , testCase "parseDep - python2-lxml>=3.1.0"
      $ parseDep "python2-lxml>=3.1.0" @?= Just (Dep "python2-lxml" . AtLeast . Ideal $ SemVer 3 1 0 [] [])
    , testCase "parseDep - foobar>1.2.3"
      $ parseDep "foobar>1.2.3" @?= Just (Dep "foobar" . MoreThan . Ideal $ SemVer 1 2 3 [] [])
    , testCase "parseDep - foobar=1.2.3"
      $ parseDep "foobar=1.2.3" @?= Just (Dep "foobar" . MustBe . Ideal $ SemVer 1 2 3 [] [])
    ]
  , testGroup "Aura.Types"
    [ testCase "simplepkg"
      $ simplepkg (PackagePath "linux-is-cool-3.2.14-1-x86_64.pkg.tar.xz")
      @?= Just (SimplePkg "linux-is-cool" . Ideal $ SemVer 3 2 14 [[Digits 1]] [])
    , testCase "simplepkg'"
      $ simplepkg' "xchat 2.8.8-19" @?= Just (SimplePkg "xchat" . Ideal $ SemVer 2 8 8 [[Digits 19]] [])
    ]
  , testGroup "Aura.Packages.Repository"
    [ testCase "extractVersion" $ extractVersion firefox @?= Just (Ideal $ SemVer 60 0 2 [[Digits 1]] [])
    ]
  , testGroup "Aura.Pacman"
    [ testCase "Parsing pacman.conf" $ do
        let p = parse config "pacman.conf" conf
            r = either (const Nothing) (\(Config c) -> Just c) p >>= M.lookup "HoldPkg"
        r @?= Just ["pacman", "glibc"]
    ]
  ]

firefox :: T.Text
firefox = "Repository      : extra\n\
\Name            : firefox\n\
\Version         : 60.0.2-1\n\
\Description     : Standalone web browser from mozilla.org"
