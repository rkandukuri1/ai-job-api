import asyncio
import os

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel

# -----------------------------------
# LOAD ENV VARIABLES
# -----------------------------------
load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY_FREE"))

# -----------------------------------
# CONFIG
# -----------------------------------
API_URL = "https://jsearch.p.rapidapi.com/search"

HEADERS = {
    # "X-RapidAPI-Key": os.getenv("X_RAPIDAPI_KEY"),
    "X-RapidAPI-Key":"123fc79263mshbb6aa5a9b340d2ep14cba6jsn89bcce76b5c3",
    "X-RapidAPI-Host":
        "jsearch.p.rapidapi.com"
}

# -----------------------------------
# FASTAPI INIT
# -----------------------------------
app = FastAPI()

# -----------------------------------
# CORS
# -----------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------------
# REQUEST MODEL
# -----------------------------------
class JobRequest(BaseModel):
    skills: str
    country: str = "us"
    page: int = 1
    limit: int = 10


# -----------------------------------
# BUILD SEARCH QUERY
# -----------------------------------
def build_search_query(
    user_skills
):

    skills = [
        s.strip()
        for s in user_skills.split(",")
        if s.strip()
    ]

    if skills:
        return (
            " ".join(skills)
            + " developer"
        )

    return "software developer"


# -----------------------------------
# FETCH JOBS
# -----------------------------------
async def fetch_jobs(
    user_skills,
    country,
    page
):

    query = build_search_query(
        user_skills
    )

    params = {
        "query": query,
        "page": str(page),
        "num_pages": "1",
        "country": country
    }

    try:

        async with httpx.AsyncClient(
            timeout=30
        ) as http_client:

            response = await http_client.get(
                API_URL,
                headers=HEADERS,
                params=params
            )

            response.raise_for_status()

            print(
                "STATUS:",
                response.status_code
            )

            data = response.json()

            print(data)

            jobs = data.get(
                "data",
                []
            )

            print("\n===================")

            print(
                "SEARCH QUERY:",
                query
            )

            print(
                "COUNTRY:",
                country
            )

            print(
                "PAGE:",
                page
            )

            print(
                "JOBS FOUND:",
                len(jobs)
            )

            print("===================\n")

            return jobs

    except Exception as e:

        print(
            "FETCH ERROR:",
            str(e)
        )

        return []


# -----------------------------------
# AI SCORE
# -----------------------------------
async def semantic_score(
    user_skills,
    title,
    description
):

    try:

        prompt = f"""
User skills:
{user_skills}

Job title:
{title}

Job description:
{description}

Give a job match score from 0 to 100.

Return ONLY the number.
"""

        response = await asyncio.to_thread(
            client.responses.create,
            model="gpt-4.1-mini",
            input=prompt
        )

        score_text = (
            response.output_text.strip()
        )

        try:

            return int(score_text)

        except:

            return 50

    except Exception as e:

        print(
            "AI SCORE ERROR:",
            str(e)
        )

        return 0


# -----------------------------------
# AI EXPLANATION
# -----------------------------------
async def explain_match(
    user_skills,
    title,
    description
):

    try:
        prompt = f"""
User skills:
{user_skills}

Job title:
{title}

Job description:
{description}

Explain in ONE short sentence why this job matches.
"""

        response = await asyncio.to_thread(
            client.responses.create,
            model="gpt-4.1-mini",
            input=prompt
        )

        return (
            response.output_text.strip()
        )

    except Exception as e:

        print(
            "AI EXPLAIN ERROR:",
            str(e)
        )

        return "No explanation available."


# -----------------------------------
# PROCESS SINGLE JOB
# -----------------------------------
async def process_job(
    job,
    user_skills
):
    
    title = job.get( "job_title", "" )
    posting_date = job.get("job_posted_at", "")
    description = job.get( "job_description", "" )
    company = job.get( "employer_name", "")
    location = job.get( "job_city", "" )

    apply_link = (

        job.get("job_apply_link")
        or job.get("job_google_link")

        or ""
    )

    try:

        score_task = semantic_score(
            user_skills,
            title,
            description
        )

        explain_task = explain_match(
            user_skills,
            title,
            description
        )

        score, explanation = (
            await asyncio.gather(
                score_task,
                explain_task
            )
        )

        return {                                                
            "title": title,
            "company": company,
            "location": location,
            "posting_date": posting_date,
            "description": description[:200] + " ...",
            "apply_link": apply_link
        }

    except Exception as e:

        print(
            "PROCESS ERROR:",
            str(e)
        )

        return {
            "title": title,
            "company": company,
            "location": location,
            "Posting Date": posting_date,
            "description" : description,
            "apply_link": apply_link
        }


# -----------------------------------
# FIND JOBS
# -----------------------------------
async def find_jobs(
    user_skills,
    country,
    page,
    limit
):

    jobs = await fetch_jobs(
        user_skills,
        country,
        page
    )

    print(
        "RAW JOB COUNT:",
        len(jobs)
    )

    # --------------------------------
    # LIMIT RESULTS
    # --------------------------------
    jobs = jobs[:limit]

    tasks = [

        process_job(
            job,
            user_skills
        )

        for job in jobs
    ]

    results = await asyncio.gather(
        *tasks
    )

    return results


# -----------------------------------
# ROOT
# -----------------------------------
@app.get("/")
async def root():

    return {

        "status": "success",
        "message":
            "AI Job Search API Running"
    }


# -----------------------------------
# HEALTH CHECK
# -----------------------------------
@app.get("/health")
async def health():

    return {
        "status": "healthy"
    }


# -----------------------------------
# JOB SEARCH ENDPOINT
# -----------------------------------
@app.post("/jobs")
async def get_jobs(
    req: JobRequest
):

    try:

        results = await find_jobs(
            req.skills,
            req.country,
            req.page,
            req.limit
        )

        return {

            "status": "success",
            "skills": req.skills,
            "country": req.country,
            "page": req.page,
            "limit": req.limit,
            "total_jobs":
                len(results),
            "jobs": results
        }

    except Exception as e:

        print(
            "ENDPOINT ERROR:",
            str(e)
        )

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )